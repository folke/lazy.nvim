local Event = require("lazy.core.handler.event")
local Loader = require("lazy.core.loader")

---@class LazyFiletypeHandler:LazyEventHandler
local M = {}
M.extends = Event

---@param value string
function M:_event(value)
  return "FileType " .. value
end

---@param plugin LazyPlugin
function M:add(plugin)
  self.super.add(self, plugin)
  if plugin.ft then
    Loader.ftdetect(plugin.dir)
  end
end

return M
