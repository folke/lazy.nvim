local Util = require("lazy.util")
local Semver = require("lazy.manage.semver")
local Config = require("lazy.core.config")

local M = {}

---@alias GitInfo {branch?:string, commit?:string, tag?:string, version?:Semver}

---@param details? boolean
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
      Util.ls(repo .. "/.git/refs/tags", function(_, name)
        if M.ref(repo, "tags/" .. name) == ret.commit then
          ret.tag = name
          ret.version = Semver.version(name)
          return false
        end
      end)
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
  return Util.head(repo .. "/.git/refs/" .. table.concat({ ... }, "/"))
end

return M
