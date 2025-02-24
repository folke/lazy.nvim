local M = {}

---@class LazyStats
M._stats = {
  -- startuptime in milliseconds till UIEnter
  startuptime = 0,
  count = 0, -- total number of plugins
  loaded = 0, -- number of loaded plugins
  ---@type table<string, number>
  times = {},
}

function M.on_ui_enter()
  local startuptime = M.track("UIEnter")
  M._stats.startuptime = startuptime / 1e6
  require("lazy.core.util").track({ start = "startuptime" }, startuptime)
  vim.api.nvim_exec_autocmds("User", { pattern = "LazyVimStarted", modeline = false })
end

function M.track(event)
  local time = require("lazy.core.util").cputime()
  M._stats.times[event] = time
  return time
end

function M.stats()
  M._stats.count = 0
  M._stats.loaded = 0
  for _, plugin in pairs(require("lazy.core.config").plugins) do
    M._stats.count = M._stats.count + 1
    if plugin._.loaded then
      M._stats.loaded = M._stats.loaded + 1
    end
  end
  return M._stats
end

return M
