--# selene:allow(incorrect_standard_library_use)
local Config = require("lazy.core.config")
local Health = require("lazy.health")
local Util = require("lazy.util")

---@class RockSpec
---@field rockspec_format string
---@field package string
---@field version string
---@field dependencies string[]
---@field build? {build_type?: string, modules?: any[]}

---@class RockManifest
---@field repository table<string, any>

local M = {}

M.dev_suffix = "-1.rockspec"
M.skip = { "lua" }
M.rewrites = {
  ["plenary.nvim"] = { "nvim-lua/plenary.nvim", lazy = true },
}
M.python = { "python3", "python" }

---@class HereRocks
M.hererocks = {}

---@param task LazyTask
function M.hererocks.build(task)
  local root = Config.options.rocks.root .. "/hererocks"

  ---@param p string
  local python = vim.tbl_filter(function(p)
    return vim.fn.executable(p) == 1
  end, M.python)[1]

  task:spawn(python, {
    args = {
      "hererocks.py",
      "--verbose",
      "-l",
      "5.1",
      "-r",
      "latest",
      root,
    },
    cwd = task.plugin.dir,
  })
end

---@param bin string
function M.hererocks.bin(bin)
  local hererocks = Config.options.rocks.root .. "/hererocks/bin"
  if Util.is_win then
    bin = bin .. ".bat"
  end
  return Util.norm(hererocks .. "/" .. bin)
end

-- check if hererocks is building
---@return boolean?
function M.hererocks.building()
  return vim.tbl_get(Config.plugins.hererocks or {}, "_", "build")
end

---@param opts? LazyHealth
function M.check(opts)
  opts = vim.tbl_extend("force", {
    error = Util.error,
    warn = Util.warn,
    ok = function() end,
  }, opts or {})

  local ok = false
  if Config.options.rocks.hererocks then
    if M.hererocks.building() then
      ok = true
    else
      ok = Health.have(M.python, opts)
      ok = Health.have(M.hererocks.bin("luarocks")) and ok
      ok = Health.have(
        M.hererocks.bin("lua"),
        vim.tbl_extend("force", opts, {
          version = "-v",
          version_pattern = "5.1",
        })
      ) and ok
    end
  else
    ok = Health.have("luarocks", opts)
    ok = (
      Health.have(
        { "lua5.1", "lua" },
        vim.tbl_extend("force", opts, {
          version = "-v",
          version_pattern = "5.1",
        })
      )
    ) and ok
  end
  return ok
end

---@param task LazyTask
function M.build(task)
  if
    not M.check({
      error = function(msg)
        task:notify_error(msg:gsub("[{}]", "`"))
      end,
      warn = function(msg)
        task:notify_warn(msg)
      end,
      ok = function(msg) end,
    })
  then
    task:notify_warn({
      "",
      "This plugin requires `luarocks`. Try one of the following:",
      " - fix your `luarocks` installation",
      Config.options.rocks.hererocks and " - disable *hererocks* with `opts.rocks.hererocks = false`"
        or " - enable `hererocks` with `opts.rocks.hererocks = true`",
      " - disable `luarocks` support completely with `opts.rocks.enabled = false`",
    })
    return
  end

  if task.plugin.name == "hererocks" then
    return M.hererocks.build(task)
  end

  local env = {}
  local luarocks = "luarocks"
  if Config.options.rocks.hererocks then
    -- hererocks is still building, so skip for now
    -- a new build will happen in the next round
    if M.hererocks.building() then
      return
    end

    local sep = Util.is_win and ";" or ":"
    local hererocks = Config.options.rocks.root .. "/hererocks/bin"
    if Util.is_win then
      hererocks = hererocks:gsub("/", "\\")
    end
    local path = vim.split(vim.env.PATH, sep)
    table.insert(path, 1, hererocks)
    env = {
      PATH = table.concat(path, sep),
    }
    if Util.is_win then
      luarocks = luarocks .. ".bat"
    end
  end

  local root = Config.options.rocks.root .. "/" .. task.plugin.name
  task:spawn(luarocks, {
    args = {
      "--tree",
      root,
      "--server",
      Config.options.rocks.server,
      "--dev",
      "--lua-version",
      "5.1",
      "make",
      "--force-fast",
    },
    cwd = task.plugin.dir,
    env = env,
  })
end

---@param file string
---@return table?
function M.parse(file)
  local ret = {}
  return pcall(function()
    loadfile(file, "t", ret)()
  end) and ret or nil
end

---@param plugin LazyPlugin
function M.deps(plugin)
  local root = Config.options.rocks.root .. "/" .. plugin.name
  ---@type RockManifest?
  local manifest = M.parse(root .. "/lib/luarocks/rocks-5.1/manifest")
  return manifest and vim.tbl_keys(manifest.repository or {})
end

---@param file string
---@return RockSpec?
function M.rockspec(file)
  return M.parse(file)
end

---@param plugin LazyPlugin
---@return LazyPkgSpec?
function M.get(plugin)
  if M.rewrites[plugin.name] then
    return {
      file = "rewrite",
      source = "lazy",
      spec = M.rewrites[plugin.name],
    }
  end

  local rockspec_file ---@type string?
  Util.ls(plugin.dir, function(path, name, t)
    if t == "file" and name:sub(-#M.dev_suffix) == M.dev_suffix then
      rockspec_file = path
      return false
    end
  end)

  if not rockspec_file then
    return
  end

  local rockspec = M.rockspec(rockspec_file)

  if not rockspec then
    return
  end

  local has_lua = not not vim.uv.fs_stat(plugin.dir .. "/lua")

  ---@type LazyPluginSpec
  local rewrites = {}

  ---@param dep string
  local rocks = vim.tbl_filter(function(dep)
    local name = dep:gsub("%s.*", "")
    if M.rewrites[name] then
      table.insert(rewrites, M.rewrites[name])
      return false
    end
    return not vim.tbl_contains(M.skip, name)
  end, rockspec.dependencies or {})

  local use = not has_lua
    or #rocks > 0
    or (
      rockspec.build
      and rockspec.build.build_type
      and rockspec.build.build_type ~= "none"
      and not (rockspec.build.build_type == "builtin" and not rockspec.build.modules)
    )

  if not use then
    if #rewrites > 0 then
      return {
        file = vim.fn.fnamemodify(rockspec_file, ":t"),
        spec = rewrites,
      }
    end
    return
  end

  local lazy = nil
  if not has_lua then
    lazy = false
  end

  return {
    file = vim.fn.fnamemodify(rockspec_file, ":t"),
    spec = {
      plugin.name,
      build = "rockspec",
      lazy = lazy,
    },
  }
end

return M
