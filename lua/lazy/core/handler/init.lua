local Util = require("lazy.core.util")
local Config = require("lazy.core.config")

---@class LazyHandler
---@field type LazyHandlerTypes
---@field extends? LazyHandler
---@field active table<string,table<string,string>>
---@field super LazyHandler
local M = {}

---@enum LazyHandlerTypes
M.types = {
  keys = "keys",
  event = "event",
  cmd = "cmd",
  ft = "ft",
}

---@type table<string,LazyHandler>
M.handlers = {}

function M.setup()
  for _, type in pairs(M.types) do
    M.handlers[type] = M.new(type)
  end
  for _, plugin in pairs(Config.plugins) do
    Util.try(function()
      M.enable(plugin)
    end, "Failed to setup handlers for " .. plugin.name)
  end
end

---@param plugin LazyPlugin
function M.disable(plugin)
  for type, handler in pairs(M.handlers) do
    if plugin[type] then
      handler:del(plugin)
    end
  end
end

---@param plugin LazyPlugin
function M.enable(plugin)
  if not plugin._.loaded then
    for type, handler in pairs(M.handlers) do
      if plugin[type] then
        handler:add(plugin)
      end
    end
  end
end

---@param type LazyHandlerTypes
function M.new(type)
  ---@type LazyHandler
  local handler = require("lazy.core.handler." .. type)
  local super = handler.extends or M
  local self = setmetatable({}, { __index = setmetatable(handler, { __index = super }) })
  self.super = super
  self.active = {}
  self.type = type
  return self
end

---@param value string
---@protected
function M:_add(value) end

---@param value string
---@protected
function M:_del(value) end

---@return string
function M:key(value)
  return value
end

---@param plugin LazyPlugin
function M:add(plugin)
  for _, value in ipairs(plugin[self.type] or {}) do
    local key = self:key(value)
    if not self.active[key] then
      self.active[key] = {}
      self:_add(value)
    end
    self.active[key][plugin.name] = plugin.name
  end
end

---@param plugin LazyPlugin
function M:del(plugin)
  for _, value in ipairs(plugin[self.type] or {}) do
    local key = self:key(value)
    if self.active[key] and self.active[key][plugin.name] then
      self.active[key][plugin.name] = nil
      if vim.tbl_isempty(self.active[key]) then
        self:_del(value)
        self.active[key] = nil
      end
    end
  end
end

return M
