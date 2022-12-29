---@type LazyCommands
local M = {}
M._start = 0

---@param spec LazySpec Should be a module name to load, or a plugin spec
---@param opts? LazyConfig
function M.setup(spec, opts)
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

  -- load module cache before anything else
  require("lazy.core.cache").setup(opts)

  local Util = require("lazy.core.util")
  local Config = require("lazy.core.config")
  local Loader = require("lazy.core.loader")
  local Plugin = require("lazy.core.plugin")

  Util.track({ plugin = "lazy.nvim" }) -- setup start
  Util.track("module", vim.loop.hrtime() - start)

  -- load config
  Util.track("config")
  Config.setup(spec, opts)
  Util.track()

  -- load the plugins
  Plugin.load()

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
  vim.cmd("do User LazyDone")
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
      "--single-branch",
      "--branch=stable", -- remove this if you want to bootstrap to HEAD
      "https://github.com/folke/lazy.nvim.git",
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
