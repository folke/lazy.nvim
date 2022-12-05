local Config = require("lazy.core.config")

local M = {}

function M.updates()
  local Checker = require("lazy.manage.checker")
  local updates = #Checker.updated
  return updates > 0 and (Config.options.ui.icons.plugin .. "" .. updates)
end

function M.has_updates()
  local Checker = require("lazy.manage.checker")
  return #Checker.updated > 0
end

return M
