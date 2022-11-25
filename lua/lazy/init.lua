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

  require("lazy.core.module").setup()

  local require_start = vim.loop.hrtime()
  local Util = require("lazy.core.util")
  local Config = require("lazy.core.config")
  local Loader = require("lazy.core.loader")
  local Plugin = require("lazy.core.plugin")

  Util.track("cache.setup", module_start - cache_start)
  Util.track("module.setup", require_start - module_start)
  Util.track("require.core", vim.loop.hrtime() - require_start)

  Util.track("setup")

  Util.track("config")
  Config.setup(opts)
  Util.track()

  Util.track("state")
  Plugin.load()
  Util.track()

  Util.track("install")
  for _, plugin in pairs(Config.plugins) do
    if not plugin.installed then
      vim.cmd("do User LazyInstallPre")
      require("lazy.manager").install({
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

  Config.plugins["lazy.nvim"].loaded.time = lazy_delta
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
