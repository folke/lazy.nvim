local M = {}

---@param spec LazySpec Should be a module name to load, or a plugin spec
---@param opts? LazyConfig
function M.setup(spec, opts)
  local module_start = vim.loop.hrtime()
  require("lazy.core.module").setup()
  local Util = require("lazy.core.util")
  local Config = require("lazy.core.config")
  local Loader = require("lazy.core.loader")
  local Plugin = require("lazy.core.plugin")

  Util.track("module", vim.loop.hrtime() - module_start)

  Util.track("setup")

  Util.track("config")
  Config.setup(spec, opts)
  Util.track()

  Plugin.load()

  Util.track("loader")
  Loader.setup()
  Util.track()

  local lazy_delta = vim.loop.hrtime() - module_start

  Util.track() -- end setup

  Loader.init_plugins()

  if Config.plugins["lazy.nvim"] then
    Config.plugins["lazy.nvim"]._.loaded.time = lazy_delta
  end

  vim.cmd("do User LazyDone")
end

function M.stats()
  local ret = { count = 0, loaded = 0 }
  for _, plugin in pairs(require("lazy.core.config").plugins) do
    ret.count = ret.count + 1
    if plugin._.loaded then
      ret.loaded = ret.loaded + 1
    end
  end
  return ret
end

function M.bootstrap()
  local lazypath = vim.fn.stdpath("data") .. "/site/pack/lazy/start/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "--single-branch",
      "https://github.com/folke/lazy.nvim.git",
      lazypath,
    })
    vim.opt.runtimepath:append(lazypath)
  end
end

return M
