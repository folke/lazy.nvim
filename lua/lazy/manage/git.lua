local Config = require("lazy.core.config")
local Process = require("lazy.manage.process")
local Semver = require("lazy.manage.semver")
local Util = require("lazy.util")

local M = {}

---@alias GitInfo {branch?:string, commit?:string, tag?:string, version?:Semver}

---@param repo string
---@param details? boolean Fetching details is slow! Don't loop over a plugin to fetch all details!
---@return GitInfo?
function M.info(repo, details)
  local line = M.head(repo)
  if line then
    ---@type string, string
    local ref, branch = line:match("ref: refs/(heads/(.*))")
    local ret = ref and {
      branch = branch,
      commit = M.ref(repo, ref),
    } or { commit = line }

    if details then
      for tag, tag_ref in pairs(M.get_tag_refs(repo)) do
        if tag_ref == ret.commit then
          ret.tag = tag
          ret.version = ret.version or Semver.version(tag)
        end
      end
    end
    return ret
  end
end

---@param a GitInfo
---@param b GitInfo
function M.eq(a, b)
  local ra = a.commit and a.commit:sub(1, 7)
  local rb = b.commit and b.commit:sub(1, 7)
  return ra == rb
end

function M.head(repo)
  return Util.head(repo .. "/.git/HEAD")
end

---@class TaggedSemver: Semver
---@field tag string

---@param spec? string
function M.get_versions(repo, spec)
  local range = Semver.range(spec or "*")
  ---@type TaggedSemver[]
  local versions = {}
  for _, tag in ipairs(M.get_tags(repo)) do
    local v = Semver.version(tag)
    ---@cast v TaggedSemver
    if v and range:matches(v) then
      v.tag = tag
      table.insert(versions, v)
    end
  end
  return versions
end

function M.get_tags(repo)
  ---@type string[]
  local ret = {}
  Util.ls(repo .. "/.git/refs/tags", function(_, name)
    ret[#ret + 1] = name
  end)
  for name in pairs(M.packed_refs(repo)) do
    local tag = name:match("^tags/(.*)")
    if tag then
      ret[#ret + 1] = tag
    end
  end
  return ret
end

---@param plugin LazyPlugin
---@return string?
function M.get_branch(plugin)
  if plugin.branch then
    return plugin.branch
  else
    -- we need to return the default branch
    -- Try origin first
    local main = M.ref(plugin.dir, "remotes/origin/HEAD")
    if main then
      local branch = main:match("ref: refs/remotes/origin/(.*)")
      if branch then
        return branch
      end
    end

    -- fallback to local HEAD
    main = assert(M.head(plugin.dir))
    return main and main:match("ref: refs/heads/(.*)")
  end
end

-- Return the last commit for the given branch
---@param repo string
---@param branch string
---@param origin? boolean
function M.get_commit(repo, branch, origin)
  if origin then
    -- origin ref might not exist if it is the same as local
    return M.ref(repo, "remotes/origin", branch) or M.ref(repo, "heads", branch)
  else
    return M.ref(repo, "heads", branch)
  end
end

---@param plugin LazyPlugin
---@return integer? seconds, or nil when disabled for this plugin
function M.get_minimum_release_age(plugin)
  local value = plugin.minimum_release_age
  if value == nil then
    value = Config.options.defaults.minimum_release_age
  end
  return Util.parse_age(value)
end

---@param plugin LazyPlugin
---@return boolean true when downgrades to an older mature commit are allowed
function M.allow_downgrade(plugin)
  local v = plugin.minimum_release_age_downgrade
  if v == nil then
    v = Config.options.defaults.minimum_release_age_downgrade
  end
  return v == true
end

--- Returns the timestamp that the age filter uses for a GitInfo target.
--- For tag targets this is the tag's creatordate (matches get_target's
--- semver-path filter); otherwise it falls back to the commit's committer
--- date. Returns nil when neither can be resolved.
---@param repo string
---@param target GitInfo
---@return integer?
function M.target_time(repo, target)
  if target.tag then
    local tag_times = M.get_tag_times(repo)
    local t = tag_times[target.tag]
    if t then
      return t
    end
  end
  if target.commit then
    return M.commit_time(repo, target.commit)
  end
  return nil
end

---@param repo string
---@param ancestor string commit SHA that should be the ancestor
---@param descendant string commit SHA that should be the descendant
---@return boolean true if `ancestor` is an ancestor of `descendant`
function M.is_ancestor(repo, ancestor, descendant)
  local ok, code = pcall(function()
    local _, c = Process.exec({ "git", "merge-base", "--is-ancestor", ancestor, descendant }, { cwd = repo })
    return c
  end)
  return ok and code == 0
end

--- Returns true when applying `target` would roll `info` back to one of its
--- ancestors (i.e. info is already newer than what minimum_release_age would
--- pick) and the active policy disallows that downgrade. Fresh installs
--- (`plugin._.cloned == true`) are exempt and always return false so the
--- initial checkout honors the age constraint.
---@param plugin LazyPlugin
---@param info GitInfo
---@param target GitInfo
---@return boolean
function M.is_downgrade(plugin, info, target)
  if M.allow_downgrade(plugin) then
    return false
  end
  if plugin._.cloned then
    return false
  end
  if not (info.commit and target.commit) then
    return false
  end
  if M.eq(info, target) then
    return false
  end
  return M.is_ancestor(plugin.dir, target.commit, info.commit)
end

--- Builds the `pending_age` state when `raw_target` (the age-ignoring target)
--- differs from what is effectively being applied. Returns nil when nothing
--- is being held back.
---@param plugin LazyPlugin
---@param info GitInfo
---@param target GitInfo?
---@param raw_target GitInfo?
---@return {from:GitInfo, to:GitInfo, eligible_at:integer?}?
function M.detect_pending_age(plugin, info, target, raw_target)
  if not (raw_target and info) then
    return nil
  end
  local effective = target or info
  if M.eq(effective, raw_target) then
    return nil
  end
  local age = M.get_minimum_release_age(plugin)
  local source_time = M.target_time(plugin.dir, raw_target)
  return {
    from = effective,
    to = raw_target,
    eligible_at = source_time and age and (source_time + age) or nil,
  }
end

---@param repo string
---@return table<string, integer>
function M.get_tag_times(repo)
  ---@type table<string, integer>
  local ret = {}
  local ok, lines = pcall(function()
    return Process.exec(
      { "git", "for-each-ref", "--format=%(refname:strip=2) %(creatordate:unix)", "refs/tags" },
      { cwd = repo }
    )
  end)
  if not ok then
    return ret
  end
  for _, line in ipairs(lines) do
    local tag, ts = line:match("^(.+) (%d+)$")
    if tag then
      ret[tag] = tonumber(ts)
    end
  end
  return ret
end

---@param repo string
---@param ref string
---@return integer?
function M.commit_time(repo, ref)
  local ok, lines = pcall(function()
    return Process.exec({ "git", "show", "-s", "--format=%ct", ref }, { cwd = repo })
  end)
  if not ok then
    return nil
  end
  return tonumber(lines[1])
end

---@param repo string
---@param branch string
---@param cutoff integer Unix timestamp; commit must be at or before this time
---@return string?
function M.last_commit_before(repo, branch, cutoff)
  local ok, lines = pcall(function()
    return Process.exec({
      "git",
      "log",
      "-1",
      "--format=%H",
      "--before=@" .. cutoff,
      "refs/remotes/origin/" .. branch,
    }, { cwd = repo })
  end)
  if not ok then
    return nil
  end
  local commit = lines[1]
  return commit and commit ~= "" and commit or nil
end

---@param plugin LazyPlugin
---@param ignore_age? boolean If true, bypass minimum_release_age filtering.
---@return GitInfo?
function M.get_target(plugin, ignore_age)
  if plugin._.is_local then
    local info = M.info(plugin.dir)
    local branch = assert(info and info.branch or M.get_branch(plugin))
    return { branch = branch, commit = M.get_commit(plugin.dir, branch, true) }
  end

  local branch = assert(M.get_branch(plugin))

  if plugin.commit then
    return {
      branch = branch,
      commit = plugin.commit,
    }
  end
  if plugin.tag then
    return {
      branch = branch,
      tag = plugin.tag,
      commit = M.ref(plugin.dir, "tags/" .. plugin.tag),
    }
  end

  local age = not ignore_age and M.get_minimum_release_age(plugin) or nil
  local cutoff = age and (os.time() - age) or nil

  local version = (plugin.version == nil and plugin.branch == nil) and Config.options.defaults.version or plugin.version
  if version then
    local versions = M.get_versions(plugin.dir, version)
    if cutoff and #versions > 0 then
      local tag_times = M.get_tag_times(plugin.dir)
      local filtered = vim.tbl_filter(function(v)
        local t = tag_times[v.tag]
        return t ~= nil and t <= cutoff
      end, versions)
      -- An age constraint that rejects every candidate tag means "wait".
      if #filtered == 0 then
        return nil
      end
      versions = filtered
    end
    local last = Semver.last(versions)
    if last then
      return {
        branch = branch,
        version = last,
        tag = last.tag,
        commit = M.ref(plugin.dir, "tags/" .. last.tag),
      }
    end
  end

  if cutoff then
    local commit = M.last_commit_before(plugin.dir, branch, cutoff)
    if commit then
      return { branch = branch, commit = commit }
    end
    return nil
  end

  return { branch = branch, commit = M.get_commit(plugin.dir, branch, true) }
end

function M.ref(repo, ...)
  local ref = table.concat({ ... }, "/")

  -- if this is a tag ref, then dereference it instead
  if ref:find("tags/", 1, true) == 1 then
    local tags = M.get_tag_refs(repo, ref)
    for _, tag_ref in pairs(tags) do
      return tag_ref
    end
  end

  -- otherwise just get the ref
  return Util.head(repo .. "/.git/refs/" .. ref) or M.packed_refs(repo)[ref]
end

function M.packed_refs(repo)
  local ok, refs = pcall(Util.read_file, repo .. "/.git/packed-refs")
  ---@type table<string,string>
  local ret = {}
  if ok then
    for _, line in ipairs(vim.split(refs, "\n")) do
      local ref, name = line:match("^(.*) refs/(.*)$")
      if ref then
        ret[name] = ref
      end
    end
  end
  return ret
end

-- this is slow, so don't use on a loop over all plugins!
---@param tagref string?
function M.get_tag_refs(repo, tagref)
  tagref = tagref or "--tags"
  ---@type table<string,string>
  local tags = {}
  local ok, lines = pcall(function()
    return Process.exec({ "git", "show-ref", "-d", tagref }, { cwd = repo })
  end)
  if not ok then
    return {}
  end
  for _, line in ipairs(lines) do
    local ref, tag = line:match("^(%w+) refs/tags/([^%^]+)%^?{?}?$")
    if ref then
      tags[tag] = ref
    end
  end
  return tags
end

---@param repo string
function M.get_origin(repo)
  return M.get_config(repo)["remote.origin.url"]
end

---@param repo string
function M.get_config(repo)
  local ok, config = pcall(Util.read_file, repo .. "/.git/config")
  if not ok then
    return {}
  end
  ---@type table<string, string>
  local ret = {}
  ---@type string
  local current_section = nil
  for line in config:gmatch("[^\n]+") do
    -- Check if the line is a section header
    local section = line:match("^%s*%[(.+)%]%s*$")
    if section then
      ---@type string
      current_section = section:gsub('%s+"', "."):gsub('"+%s*$', "")
    else
      -- Ignore comments and blank lines
      if not line:match("^%s*[#;]") and line:match("%S") then
        local key, value = line:match("^%s*(%S+)%s*=%s*(.+)%s*$")
        ret[current_section .. "." .. key] = value
      end
    end
  end
  return ret
end

function M.count(repo, commit1, commit2)
  local lines = Process.exec({ "git", "rev-list", "--count", commit1 .. ".." .. commit2 }, { cwd = repo })
  return tonumber(lines[1] or "0") or 0
end

function M.age(repo, commit)
  local lines = Process.exec({ "git", "show", "-s", "--format=%cr", "--date=short", commit }, { cwd = repo })
  return lines[1] or ""
end

return M
