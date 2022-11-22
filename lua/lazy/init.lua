local M = {}

---@param opts? LazyConfig
function M.setup(opts)
  local done = false
  -- table.insert(package.loaders, 1, function(modname)
  --   if not done and modname:find("lazy") == 1 then
  --     dd(modname)
  --   end
  -- end)
  -- Loading order
  -- 1. load module cache
  -- 2. if changes, then reload

  local cache_start = vim.loop.hrtime()
  require("lazy.core.cache").setup()

  local module_start = vim.loop.hrtime()
  local Module = require("lazy.core.module").setup()

  local require_start = vim.loop.hrtime()
  local Util = require("lazy.core.util")
  local Config = require("lazy.core.config")
  local Loader = require("lazy.core.loader")
  local State = require("lazy.core.state")

  Util.track("cache.setup", module_start - cache_start)
  Util.track("module.setup", require_start - module_start)
  Util.track("require.core", vim.loop.hrtime() - require_start)

  Util.track("setup")

  Util.track("config")
  Config.setup(opts)
  Util.track()

  Util.track("plugins")
  if Module.changed or not State.load() then
    -- rebuild state
    local Plugin = require("lazy.plugin")
    Module.add_module(vim.fn.stdpath("config") .. "/lua/" .. Config.options.plugins:gsub("%.", "/"))
    vim.schedule(function()
      vim.notify("Reloading")
    end)
    Util.track("normalize")
    Plugin.normalize(require(Config.options.plugins))
    if not Config.plugins.lazy then
      Plugin.plugin({
        "folke/lazy.nvim",
        opt = false,
      })
    end
    Util.track()

    Util.track("process")
    Plugin.process()
    Util.track()
  end
  Util.track()

  Util.track("install")
  for _, plugin in pairs(Config.plugins) do
    if not plugin.installed then
      require("lazy.manager").install({
        wait = true,
      })
      break
    end
  end
  Util.track()

  Util.track("loader")
  Loader.setup()
  Util.track()

  Util.track() -- end setup

  Loader.init_plugins()
  done = true

  vim.cmd("do User LazyDone")
end

function M.stats()
  local ret = {
    count = 0,
    loaded = 0,
  }

  for _, plugin in pairs(require("lazy.core.config").plugins) do
    ret.count = ret.count + 1

    if plugin.loaded then
      ret.loaded = ret.loaded + 1
    end
  end

  return ret
end

return M
