local Config = require("lazy.core.config")
local Util = require("lazy.core.util")
local Module = require("lazy.core.module")
local State = require("lazy.core.state")

local M = {}

---@class LazyPlugin
---@field [1] string
---@field name string display name and name used for plugin config files
---@field uri string
---@field branch? string
---@field dir string
---@field enabled? boolean
---@field opt? boolean
---@field init? fun(LazyPlugin) Will always be run
---@field config? fun(LazyPlugin) Will be executed when loading the plugin
---@field event? string|string[]
---@field cmd? string|string[]
---@field ft? string|string[]
---@field module? string|string[]
---@field keys? string|string[]
---@field requires? string[]
---@field loaded? {[string]:string, time:number}
---@field installed? boolean
---@field run? string|fun()
---@field tasks? LazyTask[]
---@field dirty? boolean
---@field updated? {from:string, to:string}

---@class LazySpec
---@field modname string
---@field modpath string
---@field plugins table<string, LazyPlugin>
local Spec = {}

---@param modname string
---@param modpath string
function Spec.load(modname, modpath)
  local self = setmetatable({}, { __index = Spec })
  self.plugins = {}
  self.modname = modname
  self.modpath = modpath
  self:normalize(assert(Module.load(modname, modpath)))
  if modname == Config.options.plugins and not self.plugins["lazy.nvim"] then
    self:add({ "folke/lazy.nvim", opt = false })
  end
  return self
end

---@param plugin LazyPlugin
function Spec:add(plugin)
  if type(plugin[1]) ~= "string" then
    Util.error("Invalid plugin spec " .. vim.inspect(plugin))
  end
  plugin.uri = plugin.uri or ("https://github.com/" .. plugin[1] .. ".git")
  if not plugin.name then
    -- PERF: optimized code to get package name without using lua patterns
    local name = plugin[1]:sub(-4) == ".git" and plugin[1]:sub(1, -5) or plugin[1]
    local slash = name:reverse():find("/", 1, true) --[[@as number?]]
    plugin.name = slash and name:sub(#name - slash + 2) or plugin[1]:gsub("%W+", "_")
  end

  M.process_local(plugin)
  local other = self.plugins[plugin.name]
  self.plugins[plugin.name] = other and vim.tbl_extend("force", self.plugins[plugin.name], plugin) or plugin
  return self.plugins[plugin.name]
end

---@param spec table
---@param results? string[]
function Spec:normalize(spec, results)
  results = results or {}
  if type(spec) == "string" then
    table.insert(results, self:add({ spec }).name)
  elseif #spec > 1 or Util.is_list(spec) then
    ---@cast spec table[]
    for _, s in ipairs(spec) do
      self:normalize(s, results)
    end
  elseif spec.enabled ~= false then
    local plugin = self:add(spec)
    plugin.requires = plugin.requires and self:normalize(plugin.requires, {}) or nil
    table.insert(results, plugin.name)
  end
  return results
end

---@param plugin LazyPlugin
function M.process_local(plugin)
  for _, pattern in ipairs(Config.options.plugins_local.patterns) do
    if plugin[1]:find(pattern, 1, true) then
      plugin.uri = Config.options.plugins_local.path .. "/" .. plugin.name
      return
    end
  end
end

---@alias LazySpecLoader fun(modname:string, modpath:string):LazySpec
---@param loader? LazySpecLoader
function M.specs(loader)
  loader = loader or Spec.load
  ---@type LazySpec[]
  local specs = {}
  table.insert(specs, loader(Config.options.plugins, Config.paths.main))
  Util.lsmod(Config.paths.plugins, function(name, modpath)
    table.insert(specs, loader(Config.options.plugins .. "." .. name, modpath))
  end)
  return specs
end

---@param loader? LazySpecLoader
function M.load(loader)
  Util.track("specs")
  local specs = M.specs(loader)
  Util.track()

  Config.plugins = {}

  for _, spec in ipairs(specs) do
    for _, plugin in pairs(spec.plugins) do
      local other = Config.plugins[plugin.name]
      Config.plugins[plugin.name] = other and vim.tbl_extend("force", other, plugin) or plugin
    end
  end

  Util.track("state")
  State.update_state()
  Util.track()
end

M.Spec = Spec

return M
