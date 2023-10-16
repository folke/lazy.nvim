local Event = require("lazy.core.handler.event")
local Loader = require("lazy.core.loader")

---@class LazyFiletypeHandler:LazyEventHandler
local M = {}
M.extends = Event

---@param plugin LazyPlugin
function M:add(plugin)
  self.super.add(self, plugin)
  if plugin.ft then
    Loader.ftdetect(plugin.dir)
  end
end

---@return LazyEvent
function M:_parse(value)
  return {
    id = value,
    event = "FileType",
    pattern = value,
  }
end

return M
