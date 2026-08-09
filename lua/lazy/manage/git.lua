local Config = require("lazy.core.config")
local Process = require("lazy.manage.process")
local Semver = require("lazy.manage.semver")

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

---@class GitTag
---@field name string
---@field commit string

--- Fetch all tags and their peeled commit hashes in a single command.
---@param repo string
---@return GitTag[]
function M.get_tags(repo)
  local lines, code = Process.exec({
    "git",
    "for-each-ref",
    "--format=%(refname:short) %(if)%(*objectname)%(then)%(*objectname)%(else)%(objectname)%(end)",
    "refs/tags/",
  }, { cwd = repo })
  if code ~= 0 then
    return {}
  end

  ---@type GitTag[]
  local tags = {}
  for _, line in ipairs(lines) do
    local name, commit = line:match("^(%S+)%s+(%x+)$")
    if name then
      table.insert(tags, { name = name, commit = commit })
    end
  end
  return tags
end

---@class TaggedSemver: Semver
---@field tag GitTag

---@param spec? string
function M.get_versions(repo, spec)
  local range = Semver.range(spec or "*")
  ---@type TaggedSemver[]
  local versions = {}
  for _, tag in ipairs(M.get_tags(repo)) do
    local v = Semver.version(tag.name)
    ---@cast v TaggedSemver
    if v and range:matches(v) then
      v.tag = tag
      table.insert(versions, v)
    end
  end
  return versions
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

  if plugin.commit then
    return {
      branch = plugin.branch,
      commit = plugin.commit,
    }
  end

  if plugin.tag then
    return {
      branch = plugin.branch,
      tag = plugin.tag,
      commit = M.ref(plugin.dir, "tags", plugin.tag),
    }
  end

  local version = (plugin.version == nil and plugin.branch == nil) and Config.options.defaults.version or plugin.version
  if version then
    local last = Semver.last(M.get_versions(plugin.dir, version))
    if last then
      return {
        branch = plugin.branch,
        version = last,
        tag = last.tag.name,
        commit = last.tag.commit,
      }
    end
  end

  local branch = assert(M.get_branch(plugin))
  return { branch = branch, commit = M.get_commit(plugin.dir, branch, true) }
end

--- Dereference a reference or tag to its commit hash.
--- The `^{commit}` suffix automatically peels annotated tags directly to their underlying commit object.
---@param repo string
---@param kind string "heads" | "tags" | "remotes/origin"
---@param name string
---@return string?
function M.ref(repo, kind, name)
  return git(repo, "rev-parse", kind .. "/" .. name .. "^{commit}")
end

--- Fast synchronous origin URL reader.
--- This must read `.git/config` directly in Lua without spawning a `git` subprocess
--- because it is called in `skip()` pre-filters during pipeline scheduling. Spawning
--- an async process in `skip()` yields the runner's main coroutine mid-loop, causing
--- race conditions and false positives.
--- Handles standard Git repositories, submodules, and worktrees.
---@param repo string
---@return string?
function M.get_origin(repo)
  local git_dir = repo .. "/.git"
  local stat = vim.uv.fs_stat(git_dir)
  if not stat then
    return
  end
  local config_file = git_dir .. "/config"
  if stat.type == "file" then
    local f = io.open(git_dir, "r")
    local content = f and f:read("*a")
    if f then
      f:close()
    end
    local path = content and content:match("gitdir:%s*(.-)%s*$")
    if path then
      config_file = vim.fs.normalize(repo .. "/" .. path .. "/config")
    end
  end
  local f = io.open(config_file, "r")
  if f then
    local config = f:read("*a")
    f:close()
    if config then
      return config:match('%[remote%s+"origin"%][^%[]*url%s*=%s*(%S+)')
    end
  end
end

return M
