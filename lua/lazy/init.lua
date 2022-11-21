local M = {}

---@param opts? LazyConfig
function M.setup(opts)
  --FIXME:  preload()

  local Cache = require("lazy.cache")

  local start = vim.loop.hrtime()
  Cache.boot()

  local Util = require("lazy.util")
  local Config = require("lazy.config")
  local Plugin = require("lazy.plugin")

  Util.track("lazy_boot", vim.loop.hrtime() - start)

  Util.track("lazy_setup")

  Util.track("lazy_config")
  Config.setup(opts)
  Util.track()

  Util.track("lazy_plugins")
  if not Cache.setup() then
    vim.schedule(function()
      vim.notify("Reloading")
    end)
    Util.track("plugin_normalize")
    Plugin.normalize(require(Config.options.plugins))
    if not Config.plugins.lazy then
      Plugin.plugin({
        "folke/lazy.nvim",
        opt = false,
      })
    end
    Util.track()

    Util.track("plugin_process")
    Plugin.process()
    Util.track()
  end
  Util.track()

  Util.track("lazy_install")
  for _, plugin in pairs(Config.plugins) do
    if not plugin.installed then
      require("lazy.manager").install({
        wait = true,
      })
      break
    end
  end
  Util.track()

  Util.track("loader_setup")
  local Loader = require("lazy.loader")
  Loader.setup()
  Util.track()

  Loader.init_plugins()

  Util.track() -- end setup
  vim.cmd("do User LazyDone")
end

function M.stats()
  local ret = {
    count = 0,
    loaded = 0,
  }

  for _, plugin in pairs(require("lazy.config").plugins) do
    ret.count = ret.count + 1

    if plugin.loaded then
      ret.loaded = ret.loaded + 1
    end
  end

  return ret
end

return M
