local Config = require("lazy.core.config")
local Util = require("lazy.core.util")
local Module = require("lazy.core.module")
local Cache = require("lazy.core.cache")
local Handler = require("lazy.core.handler")

local M = {}

---@alias CachedPlugin LazyPlugin | {_funs: string[]}
local skip = { _ = true, dir = true }
local funs = { config = true, init = true, run = true }

M.dirty = false

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
---@field modname string
---@field modpath string
---@field plugins table<string, LazyPlugin>
---@field funs? table<string, string[]>
local Spec = {}
M.Spec = Spec

---@param spec? LazySpec
function Spec.new(spec)
  local self = setmetatable({}, { __index = Spec })
  self.plugins = {}
  self.modname = nil
  self.modpath = nil
  if spec then
    self:normalize(spec)
  end
  return self
end

---@param modname string
---@param modpath string
function Spec.load(modname, modpath)
  local self = setmetatable({}, { __index = Spec })
  self.plugins = {}
  self.modname = modname
  self.modpath = modpath
  local mod, cached = Module.load(modname, modpath)
  M.dirty = M.dirty or not cached
  self:normalize(assert(mod))
  if modname == Config.options.plugins and not self.plugins["lazy.nvim"] then
    self:add({ "folke/lazy.nvim", opt = false })
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

  M.process_local(plugin)
  local other = self.plugins[plugin.name]
  self.plugins[plugin.name] = other and M.merge(other, plugin) or plugin
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

---@param spec LazySpecLoader
function Spec.revive(spec)
  if spec.funs then
    ---@type LazySpecLoader
    local loaded = nil
    for fun, plugins in pairs(spec.funs) do
      for _, name in pairs(plugins) do
        ---@diagnostic disable-next-line: no-unknown
        spec.plugins[name][fun] = function(...)
          loaded = loaded or Spec.load(spec.modname, spec.modpath)
          return loaded.plugins[name][fun](...)
        end
      end
    end
  end
  return spec
end

---@param old LazyPlugin
---@param new LazyPlugin
---@return LazyPlugin
function M.merge(old, new)
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

---@param opts? {clean:boolean, installed:boolean, plugins?: LazyPlugin[]}
function M.update_state(opts)
  opts = opts or {}

  ---@type table<"opt"|"start", table<string,FileType>>
  local installed = { opt = {}, start = {} }
  if opts.installed ~= false then
    for opt, packs in pairs(installed) do
      Util.ls(Config.options.packpath .. "/" .. opt, function(_, name, type)
        if type == "directory" or type == "link" then
          packs[name] = type
        end
      end)
    end
  end

  for _, plugin in pairs(opts.plugins or Config.plugins) do
    plugin._ = plugin._ or {}
    plugin[1] = plugin["1"] or plugin[1]
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

  if opts.clean then
    Config.to_clean = {}
    for opt, packs in pairs(installed) do
      for pack in pairs(packs) do
        table.insert(Config.to_clean, {
          name = pack,
          pack = pack,
          dir = Config.options.packpath .. "/" .. opt .. "/" .. pack,
          opt = opt == "opt",
          _ = {
            installed = true,
          },
        })
      end
    end
  end
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

---@param cache? table<string,LazySpecLoader>
function M.specs(cache)
  ---@type LazySpecLoader[]
  local specs = {}

  local function _load(name, modpath)
    local modname = Config.options.plugins .. (name and ("." .. name) or "")
    Util.try(function()
      local spec = cache and cache[modname]
      spec = spec and not Module.is_dirty(modname, modpath) and Spec.revive(spec) or Spec.load(modname, modpath)
      table.insert(specs, spec)
    end, "Failed to load **" .. modname .. "**")
  end

  _load(nil, Config.paths.main)
  Util.lsmod(Config.paths.plugins, _load)
  return specs
end

function M.load()
  ---@type boolean, LazyState?
  local ok, state = pcall(vim.json.decode, Cache.get("cache.state"))
  if not (ok and state and vim.deep_equal(Config.options, state.config)) then
    M.dirty = true
    state = nil
  end

  -- load specs
  Util.track("specs")
  local specs = M.specs(state and state.specs)
  Util.track()

  -- merge
  Config.plugins = {}
  for _, spec in ipairs(specs) do
    for _, plugin in pairs(spec.plugins) do
      local other = Config.plugins[plugin.name]
      Config.plugins[plugin.name] = other and M.merge(other, plugin) or plugin
    end
  end

  Util.track("state")
  M.update_state()
  Util.track()

  if M.dirty then
    Cache.dirty = true
  elseif state then
    require("lazy.core.handler")._groups = state.handlers
  end
end

function M.save()
  ---@class LazyState
  local state = {
    ---@type table<string, LazySpecLoader>
    specs = {},
    handlers = require("lazy.core.handler").group(Config.plugins, true),
    config = Config.options,
  }

  for _, spec in ipairs(M.specs()) do
    spec.funs = {}
    state.specs[spec.modname] = spec
    for _, plugin in pairs(spec.plugins) do
      if plugin.init or (plugin.opt == false and plugin.config) then
        -- no use in caching specs that need init,
        -- or specs that are in start and have a config,
        -- since we'll load the real spec during startup anyway
        state.specs[spec.modname] = nil
        break
      end
      ---@cast plugin CachedPlugin
      for k, v in pairs(plugin) do
        if type(v) == "function" then
          if funs[k] then
            spec.funs[k] = spec.funs[k] or {}
            table.insert(spec.funs[k], plugin.name)
          end
          plugin[k] = nil
        elseif skip[k] then
          plugin[k] = nil
        end
      end
    end
  end
  Cache.set("cache.state", vim.json.encode(state))
end

return M
