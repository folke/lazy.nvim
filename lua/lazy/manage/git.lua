local Config = require("lazy.core.config")
local Process = require("lazy.manage.process")
local Semver = require("lazy.manage.semver")
local Util = require("lazy.util")

local M = {}

---@param repo string
---@param ... string
---@return string?
local function git(repo, ...)
  local lines, code = Process.exec({ "git", ... }, { cwd = repo })
  if code == 0 and lines[1] and lines[1] ~= "" then
    return lines[1]
  end
end

---@alias GitInfo {branch?:string, commit?:string, tag?:string, version?:Semver}

---@param repo string
---@return GitInfo?
function M.info(repo)
  -- Use `git rev-list -1 --format=%D HEAD` to fetch commit SHA and ref decorations in 1 command.
  -- Line 1: `commit <hex-hash>`
  -- Line 2: comma-space-separated decorations, e.g.:
  --   Attached: `HEAD -> main, tag: v1.1.0, origin/main`
  --   Detached: `HEAD, tag: v1.0.0`
  local lines, code = Process.exec({ "git", "rev-list", "-1", "--format=%D", "HEAD" }, { cwd = repo })
  if code ~= 0 or not lines[1] then
    return
  end

  local ret = { commit = lines[1]:match("^commit (%x+)$") }
  if not ret.commit then
    return
  end

  -- Git ref names cannot contain spaces, so splitting by ", " is safe and unambiguous
  for item in ((lines[2] or "") .. ", "):gmatch("(.-), ") do
    ret.branch = ret.branch or item:match("^HEAD %-> (.*)")
    local tag = item:match("^tag: (.*)")
    if tag then
      local v = Semver.version(tag)
      if v and (not ret.version or v > ret.version) then
        ret.tag = tag
        ret.version = v
      elseif not ret.tag then
        ret.tag = tag
      end
    end
  end

  return ret
end

---@param a GitInfo
---@param b GitInfo
function M.eq(a, b)
  local ra = a.commit and a.commit:sub(1, 7)
  local rb = b.commit and b.commit:sub(1, 7)
  return ra == rb
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
  local lines, code = Process.exec({ "git", "for-each-ref", "--format=%(refname:short)", "refs/tags/" }, { cwd = repo })
  return code == 0 and vim.tbl_filter(function(s)
    return s ~= ""
  end, lines) or {}
end

---@param plugin LazyPlugin
---@return string?
function M.get_branch(plugin)
  if plugin.branch then
    return plugin.branch
  end

  -- we need to return the default branch
  -- Try origin first
  local main = git(plugin.dir, "symbolic-ref", "refs/remotes/origin/HEAD")
  if main then
    local branch = main:match("refs/remotes/origin/(.*)")
    if branch then
      return branch
    end
  end

  -- fallback to local HEAD
  local info = assert(M.info(plugin.dir))
  return info.branch
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
---@return GitInfo?
function M.get_target(plugin)
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

  local version = (plugin.version == nil and plugin.branch == nil) and Config.options.defaults.version or plugin.version
  if version then
    local last = Semver.last(M.get_versions(plugin.dir, version))
    if last then
      return {
        branch = branch,
        version = last,
        tag = last.tag,
        commit = M.ref(plugin.dir, "tags/" .. last.tag),
      }
    end
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

  return git(repo, "rev-parse", ref)
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
