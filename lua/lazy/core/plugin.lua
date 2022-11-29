local Config = require("lazy.core.config")
local Util = require("lazy.core.util")
local Module = require("lazy.core.module")
local Handler = require("lazy.core.handler")

local M = {}

---@class LazyPluginHooks
---@field init? fun(LazyPlugin) Will always be run
---@field config? fun(LazyPlugin) Will be executed when loading the plugin
---@field run? string|fun()

---@class LazyPluginState
---@field loaded? {[string]:string, time:number}
---@field installed boolean
---@field tasks? LazyTask[]
---@field dirty? boolean
---@field updated? {from:string, to:string}
---@field is_local boolean
---@field is_symlink? boolean
---@field cloned? boolean

---@class LazyPluginRef
---@field branch? string
---@field tag? string
---@field commit? string
---@field version? string
---@field pin? boolean

---@class LazyPlugin: LazyPluginHandlers,LazyPluginHooks,LazyPluginRef
---@field [1] string
---@field name string display name and name used for plugin config files
---@field uri string
---@field dir string
---@field dep? boolean True if this plugin is only in the spec as a dependency
---@field enabled? boolean|(fun():boolean)
---@field opt? boolean
---@field dependencies? string[]
---@field _ LazyPluginState

---@alias LazySpec string|LazyPlugin|LazySpec[]|{dependencies:LazySpec}

---@class LazySpecLoader
---@field plugins table<string, LazyPlugin>
local Spec = {}
M.Spec = Spec

---@param spec? LazySpec
function Spec.new(spec)
  local self = setmetatable({}, { __index = Spec })
  self.plugins = {}
  if spec then
    self:normalize(spec)
  end
  return self
end

---@param plugin LazyPlugin
---@param is_dep? boolean
function Spec:add(plugin, is_dep)
  local pkg = plugin[1]
  if type(pkg) ~= "string" then
    Util.error("Invalid plugin spec " .. vim.inspect(plugin))
  end

  if not plugin.uri then
    local c = pkg:sub(1, 1)
    if c == "~" then
      plugin.uri = vim.loop.os_getenv("HOME") .. pkg:sub(2)
    elseif c == "/" then
      plugin.uri = pkg
    elseif pkg:sub(1, 4) == "http" or pkg:sub(1, 3) == "ssh" then
      plugin.uri = pkg
    else
      plugin.uri = ("https://github.com/" .. pkg .. ".git")
    end
  end

  -- PERF: optimized code to get package name without using lua patterns
  if not plugin.name then
    local name = pkg:sub(-4) == ".git" and pkg:sub(1, -5) or pkg
    local slash = name:reverse():find("/", 1, true) --[[@as number?]]
    plugin.name = slash and name:sub(#name - slash + 2) or pkg:gsub("%W+", "_")
  end

  plugin.dep = is_dep

  -- check for plugins that should be local
  for _, pattern in ipairs(Config.options.plugins_local.patterns) do
    if plugin[1]:find(pattern, 1, true) then
      plugin.uri = Config.options.plugins_local.path .. "/" .. plugin.name
      break
    end
  end

  local other = self.plugins[plugin.name]
  self.plugins[plugin.name] = other and self:merge(other, plugin) or plugin
  return self.plugins[plugin.name]
end

---@param spec LazySpec
---@param results? string[]
---@param is_dep? boolean
function Spec:normalize(spec, results, is_dep)
  results = results or {}
  if type(spec) == "string" then
    table.insert(results, self:add({ spec }, is_dep).name)
  elseif #spec > 1 or Util.is_list(spec) then
    ---@cast spec LazySpec[]
    for _, s in ipairs(spec) do
      self:normalize(s, results, is_dep)
    end
  elseif spec.enabled == nil or spec.enabled == true or (type(spec.enabled) == "function" and spec.enabled()) then
    ---@cast spec LazyPlugin
    local plugin = self:add(spec, is_dep)
    plugin.dependencies = plugin.dependencies and self:normalize(plugin.dependencies, {}, true) or nil
    table.insert(results, plugin.name)
  end
  return results
end

---@param old LazyPlugin
---@param new LazyPlugin
---@return LazyPlugin
function Spec:merge(old, new)
  local is_dep = old.dep and new.dep

  ---@diagnostic disable-next-line: no-unknown
  for k, v in pairs(new) do
    if k == "dep" then
    elseif old[k] ~= nil and old[k] ~= v then
      if Handler.handlers[k] then
        local values = type(v) == "string" and { v } or v
        vim.list_extend(values, type(old[k]) == "string" and { old[k] } or old[k])
        ---@diagnostic disable-next-line: no-unknown
        old[k] = values
      else
        error("Merging plugins is not supported for key `" .. k .. "`")
      end
    else
      ---@diagnostic disable-next-line: no-unknown
      old[k] = v
    end
  end
  old.dep = is_dep
  return old
end

function M.update_state()
  ---@type table<"opt"|"start", table<string,FileType>>
  local installed = { opt = {}, start = {} }
  for opt, packs in pairs(installed) do
    Util.ls(Config.options.packpath .. "/" .. opt, function(_, name, type)
      if type == "directory" or type == "link" then
        packs[name] = type
      end
    end)
  end

  for _, plugin in pairs(Config.plugins) do
    plugin._ = plugin._ or {}
    if plugin.opt == nil then
      plugin.opt = plugin.dep
        or Config.options.opt
        or plugin.module
        or plugin.event
        or plugin.keys
        or plugin.ft
        or plugin.cmd
      plugin.opt = plugin.opt and true or false
    end
    local opt = plugin.opt and "opt" or "start"
    plugin.dir = Config.options.packpath .. "/" .. opt .. "/" .. plugin.name
    plugin._.is_local = plugin.uri:sub(1, 4) ~= "http" and plugin.uri:sub(1, 3) ~= "git"
    plugin._.is_symlink = installed[opt][plugin.name] == "link"
    plugin._.installed = installed[opt][plugin.name] ~= nil
    if plugin._.is_local == plugin._.is_symlink then
      installed[opt][plugin.name] = nil
    end
  end

  Config.to_clean = {}
  for opt, packs in pairs(installed) do
    for pack, dir_type in pairs(packs) do
      table.insert(Config.to_clean, {
        name = pack,
        dir = Config.options.packpath .. "/" .. opt .. "/" .. pack,
        opt = opt == "opt",
        _ = {
          installed = true,
          is_symlink = dir_type == "link",
          is_local = dir_type == "link",
        },
      })
    end
  end
end

function M.spec()
  local spec = Spec.new()

  local function _load(name, modpath)
    local modname = Config.options.plugins .. (name and ("." .. name) or "")
    Util.try(function()
      local mod = Module.load(modname, modpath)
      spec:normalize(assert(mod))
    end, "Failed to load **" .. modname .. "**")
  end

  _load(nil, Config.paths.main)
  Util.lsmod(Config.paths.plugins, _load)
  return spec
end

function M.load()
  -- load specs
  Util.track("spec")
  local spec = M.spec()
  if not spec.plugins["lazy.nvim"] then
    spec:add({ "folke/lazy.nvim", opt = false })
  end
  Config.plugins = spec.plugins
  Util.track()

  Util.track("state")
  M.update_state()
  Util.track()
end

return M
