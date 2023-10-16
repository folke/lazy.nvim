local Config = require("lazy.core.config")
local Util = require("lazy.core.util")

---@class LazyHandler
---@field type LazyHandlerTypes
---@field extends? LazyHandler
---@field active table<string,table<string,string>>
---@field managed table<string,string>
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

M.did_setup = false

function M.init()
  for _, type in pairs(M.types) do
    M.handlers[type] = M.new(type)
  end
end

function M.setup()
  M.did_setup = true
  for _, plugin in pairs(Config.plugins) do
    Util.try(function()
      M.enable(plugin)
    end, "Failed to setup handlers for " .. plugin.name)
  end
end

---@param plugin LazyPlugin
function M.disable(plugin)
  if not plugin._.handlers_enabled then
    return
  end
  plugin._.handlers_enabled = false
  for type, handler in pairs(M.handlers) do
    if plugin[type] then
      handler:del(plugin)
    end
  end
end

---@param plugin LazyPlugin
function M.enable(plugin)
  if not plugin._.loaded then
    if plugin._.handlers_enabled then
      return
    end
    for type, handler in pairs(M.handlers) do
      if plugin[type] then
        handler:add(plugin)
      end
    end
    plugin._.handlers_enabled = true
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
  self.managed = {}
  self.type = type
  return self
end

---@param _value string
---@protected
function M:_add(_value) end

---@param _value string
---@protected
function M:_del(_value) end

---@param plugin LazyPlugin
function M:values(plugin)
  local Plugin = require("lazy.core.plugin")
  ---@type table<string,any>
  local values = {}
  ---@diagnostic disable-next-line: no-unknown
  for _, value in ipairs(Plugin.values(plugin, self.type, true)) do
    values[value] = value
  end
  return values
end

---@param plugin LazyPlugin
function M:add(plugin)
  for key, value in pairs(self:values(plugin)) do
    if not self.active[key] then
      self.active[key] = {}
      self:_add(value)
      self.managed[key] = key
    end
    self.active[key][plugin.name] = plugin.name
  end
end

---@param plugin LazyPlugin
function M:del(plugin)
  for key, value in pairs(self:values(plugin)) do
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
