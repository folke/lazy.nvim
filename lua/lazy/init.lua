local M = {}

---@param opts? LazyConfig
function M.setup(opts)
  local cache_start = vim.loop.hrtime()
  require("lazy.core.cache").setup()

  local module_start = vim.loop.hrtime()
  require("lazy.core.module").setup()
  local Util = require("lazy.core.util")
  local Config = require("lazy.core.config")
  local Loader = require("lazy.core.loader")
  local Plugin = require("lazy.core.plugin")

  Util.track("cache", module_start - cache_start)
  Util.track("module", vim.loop.hrtime() - module_start)

  Util.track("setup")

  Util.track("config")
  Config.setup(opts)
  Util.track()

  Util.track("state")
  Plugin.load()
  Util.track()

  Util.track("install")
  for _, plugin in pairs(Config.plugins) do
    if not plugin._.installed then
      vim.cmd("do User LazyInstallPre")
      require("lazy.manage").install({
        wait = true,
        show = Config.options.interactive,
      })
      break
    end
  end
  Util.track()

  Util.track("loader")
  Loader.setup()
  Util.track()

  Util.track() -- end setup

  local lazy_delta = vim.loop.hrtime() - cache_start

  Loader.init_plugins()

  if Config.plugins["lazy.nvim"] then
    Config.plugins["lazy.nvim"]._.loaded.time = lazy_delta
  end

  vim.cmd("do User LazyDone")
end

function M.stats()
  local ret = {
    count = 0,
    loaded = 0,
  }

  for _, plugin in pairs(require("lazy.core.config").plugins) do
    ret.count = ret.count + 1

    if plugin._.loaded then
      ret.loaded = ret.loaded + 1
    end
  end

  return ret
end

return M
