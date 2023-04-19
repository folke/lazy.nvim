---@type LazyCommands
local M = {}
M._start = 0

---@overload fun(opts: LazyConfig)
---@overload fun(spec:LazySpec, opts: LazyConfig)
function M.setup(spec, opts)
  if type(spec) == "table" and spec.spec then
    ---@cast spec LazyConfig
    opts = spec
  else
    opts = opts or {}
    opts.spec = spec
  end

  M._start = M._start == 0 and vim.loop.hrtime() or M._start
  if vim.g.lazy_did_setup then
    return vim.notify(
      "Re-sourcing your config is not supported with lazy.nvim",
      vim.log.levels.WARN,
      { title = "lazy.nvim" }
    )
  end
  vim.g.lazy_did_setup = true
  if not vim.go.loadplugins then
    return
  end
  if vim.fn.has("nvim-0.8.0") ~= 1 then
    return vim.notify("lazy.nvim requires Neovim >= 0.8.0", vim.log.levels.ERROR, { title = "lazy.nvim" })
  end
  if not (pcall(require, "ffi") and jit and jit.version) then
    return vim.notify("lazy.nvim requires Neovim built with LuaJIT", vim.log.levels.ERROR, { title = "lazy.nvim" })
  end
  local start = vim.loop.hrtime()

  -- use the NEovim cache if available
  if vim.loader and vim.fn.has("nvim-0.9.1") == 1 then
    package.loaded["lazy.core.cache"] = vim.loader
  end

  local Cache = require("lazy.core.cache")

  local enable_cache = not (
    opts
    and opts.performance
    and opts.performance.cache
    and opts.performance.cache.enabled == false
  )
  -- load module cache before anything else
  if enable_cache then
    Cache.enable()
  end

  require("lazy.stats").track("LazyStart")

  local Util = require("lazy.core.util")
  local Config = require("lazy.core.config")
  local Loader = require("lazy.core.loader")

  table.insert(package.loaders, 3, Loader.loader)

  if vim.g.profile_loaders then
    Cache.profile_loaders()
  end

  Util.track({ plugin = "lazy.nvim" }) -- setup start
  Util.track("module", vim.loop.hrtime() - start)

  -- load config
  Util.track("config")
  Config.setup(opts)
  Util.track()

  -- setup loader and handlers
  Loader.setup()

  -- correct time delta and loaded
  local delta = vim.loop.hrtime() - start
  Util.track().time = delta -- end setup
  if Config.plugins["lazy.nvim"] then
    Config.plugins["lazy.nvim"]._.loaded = { time = delta, source = "init.lua" }
  end

  -- load plugins with lazy=false or Plugin.init
  Loader.startup()

  -- all done!
  vim.api.nvim_exec_autocmds("User", { pattern = "LazyDone", modeline = false })
  require("lazy.stats").track("LazyDone")
end

function M.stats()
  return require("lazy.stats").stats()
end

function M.bootstrap()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", -- latest stable release
      lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)
end

---@return LazyPlugin[]
function M.plugins()
  return vim.tbl_values(require("lazy.core.config").plugins)
end

setmetatable(M, {
  __index = function(_, key)
    return function(...)
      return require("lazy.view.commands").commands[key](...)
    end
  end,
})

return M
