local Config = require("lazy.core.config")

---@class LazyPluginHandlers: table<LazyHandlerTypes, string|string[]>
---@field event? string|string[]
---@field cmd? string|string[]
---@field ft? string|string[]
---@field keys? string|string[]

---@class LazyHandler
---@field type LazyHandlerTypes
---@field extends? LazyHandler
---@field active table<string,table<string,string>>
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
    M.enable(plugin)
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
  local self = setmetatable({}, {
    __index = function(_, k)
      return handler[k] or (handler.extends and handler.extends[k]) or M[k]
    end,
  })
  self.active = {}
  self.type = type
  self:init()
  return self
end

---@protected
function M:init() end

---@param plugin LazyPlugin
---@param value string
---@protected
function M:_add(plugin, value) end

---@param plugin LazyPlugin
---@param value string
---@protected
function M:_del(plugin, value) end

---@param value string
function M:_value(value)
  return value
end

---@param values? string|string[]
---@param fn fun(value:string)
function M:foreach(values, fn)
  if type(values) == "string" then
    fn(values)
  elseif values ~= nil then
    for _, value in ipairs(values) do
      fn(value)
    end
  end
end

---@param plugin LazyPlugin
function M:add(plugin)
  self:foreach(plugin[self.type], function(value)
    value = self:_value(value)
    if not (self.active[value] and self.active[value][plugin.name]) then
      self.active[value] = self.active[value] or {}
      self.active[value][plugin.name] = plugin.name
      self:_add(plugin, value)
    end
  end)
end

---@param plugin LazyPlugin
function M:del(plugin)
  self:foreach(plugin[self.type], function(value)
    value = self:_value(value)
    if self.active[value] and self.active[value][plugin.name] then
      self.active[value][plugin.name] = nil
      self:_del(plugin, value)
    end
  end)
end

return M
