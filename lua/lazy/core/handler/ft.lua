local Event = require("lazy.core.handler.event")
local Loader = require("lazy.core.loader")

---@class LazyFiletypeHandler:LazyEventHandler
local M = {}
M.extends = Event

---@param value string
function M:_value(value)
  return "FileType " .. value
end

---@param plugin LazyPlugin
---@param value string
function M:_add(plugin, value)
  Loader.ftdetect(plugin)
  Event._add(self, plugin, value)
end

return M
