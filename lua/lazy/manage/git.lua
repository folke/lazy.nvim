local Util = require("lazy.util")
local Semver = require("lazy.manage.semver")
local Config = require("lazy.core.config")
local Process = require("lazy.manage.process")

local M = {}

---@alias GitInfo {branch?:string, commit?:string, tag?:string, version?:Semver}

---@param repo string
---@param details? boolean Fetching details is slow! Don't loop over a plugin to fetch all details!
---@return GitInfo?
function M.info(repo, details)
  local line = Util.head(repo .. "/.git/HEAD")
  if line then
    ---@type string, string
    local ref, branch = line:match("ref: (refs/heads/(.*))")
    local ret = ref and {
      branch = branch,
      commit = Util.head(repo .. "/.git/" .. ref),
    } or { commit = line }

    if details then
      for tag, tag_ref in pairs(M.get_tag_refs(repo)) do
        if tag_ref == ret.commit then
          ret.tag = tag
          ret.version = Semver.version(tag)
          break
        end
      end
    end
    return ret
  end
end

---@class TaggedSemver: Semver
---@field tag string

---@param spec? string
function M.get_versions(repo, spec)
  local range = Semver.range(spec or "*")
  ---@type TaggedSemver[]
  local versions = {}
  Util.ls(repo .. "/.git/refs/tags", function(_, name)
    local v = Semver.version(name)
    ---@cast v TaggedSemver
    if v and range:matches(v) then
      v.tag = name
      table.insert(versions, v)
    end
  end)
  return versions
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
    main = assert(Util.head(plugin.dir .. "/.git/HEAD"))
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
---@return GitInfo?
function M.get_target(plugin)
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
  local version = plugin.version or Config.options.defaults.version
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
  ---@diagnostic disable-next-line: return-type-mismatch
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
  return Util.head(repo .. "/.git/refs/" .. ref)
end

-- this is slow, so don't use on a loop over all plugins!
---@param tagref string?
function M.get_tag_refs(repo, tagref)
  tagref = tagref or "--tags"
  ---@type table<string,string>
  local tags = {}
  local lines = Process.exec({ "git", "show-ref", "-d", tagref }, { cwd = repo })
  for _, line in ipairs(lines) do
    local ref, tag = line:match("^(%w+) refs/tags/([^%^]+)%^?{?}?$")
    if ref then
      tags[tag] = ref
    end
  end
  return tags
end

return M
