local Config = require("lazy.core.config")
local Manage = require("lazy.manage")
local Util = require("lazy.util")
local Git = require("lazy.manage.git")

local M = {}

M.running = false
M.updated = {}

function M.start()
  M.fast_check()
  M.check()
end

function M.fast_check()
  for _, plugin in pairs(Config.plugins) do
    local info = Git.info(plugin.dir)
    local target = Git.get_target(plugin)
    if info and target and info.commit ~= target.commit then
      plugin._.has_updates = true
    end
  end
  M.report()
end

function M.check()
  Manage.check({
    show = false,
    concurrency = Config.options.checker.concurrency,
  }):wait(function()
    M.report()
    vim.defer_fn(M.check, Config.options.checker.frequency * 1000)
  end)
end

function M.report()
  local lines = {}
  for _, plugin in pairs(Config.plugins) do
    if plugin._.has_updates and not vim.tbl_contains(M.updated, plugin.name) then
      table.insert(lines, "- **" .. plugin.name .. "**")
      table.insert(M.updated, plugin.name)
    end
  end
  if #lines > 0 and Config.options.checker.notify then
    table.insert(lines, 1, "# Plugin Updates")
    Util.info(lines)
  end
end

return M
