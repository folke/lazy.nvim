local Config = require("lazy.core.config")
local Manage = require("lazy.manage")
local Util = require("lazy.util")
local Git = require("lazy.manage.git")

local M = {}

M.running = false
M.updated = {}
M.reported = {}

function M.start()
  M.fast_check()
  M.check()
end

---@param opts? {report:boolean} report defaults to true
function M.fast_check(opts)
  opts = opts or {}
  for _, plugin in pairs(Config.plugins) do
    if not plugin.pin and plugin._.installed then
      plugin._.updates = nil
      local info = Git.info(plugin.dir)
      local ok, target = pcall(Git.get_target, plugin)
      if ok and info and target and info.commit ~= target.commit then
        plugin._.updates = { from = info, to = target }
      end
    end
  end
  M.report(opts.report ~= false)
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

---@param notify? boolean
function M.report(notify)
  local lines = {}
  M.updated = {}
  for _, plugin in pairs(Config.plugins) do
    if plugin._.updates then
      table.insert(M.updated, plugin.name)
      if not vim.tbl_contains(M.reported, plugin.name) then
        table.insert(lines, "- **" .. plugin.name .. "**")
        table.insert(M.reported, plugin.name)
      end
    end
  end
  if #lines > 0 and notify and Config.options.checker.notify then
    table.insert(lines, 1, "# Plugin Updates")
    Util.info(lines)
  end
end

return M
