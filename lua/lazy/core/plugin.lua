local Config = require("lazy.core.config")
local Util = require("lazy.core.util")
local Handler = require("lazy.core.handler")
local Cache = require("lazy.core.cache")

---@class LazyCorePlugin
local M = {}

---@class LazySpecLoader
---@field plugins table<string, LazyPlugin>
---@field modules string[]
---@field notifs {msg:string, level:number, file?:string}[]
---@field importing? string
local Spec = {}
M.Spec = Spec

---@param spec? LazySpec
function Spec.new(spec)
  local self = setmetatable({}, { __index = Spec })
  self.plugins = {}
  self.modules = {}
  self.notifs = {}
  if spec then
    self:normalize(spec)
  end
  return self
end

-- PERF: optimized code to get package name without using lua patterns
function Spec.get_name(pkg)
  local name = pkg:sub(-4) == ".git" and pkg:sub(1, -5) or pkg
  local slash = name:reverse():find("/", 1, true) --[[@as number?]]
  return slash and name:sub(#name - slash + 2) or pkg:gsub("%W+", "_")
end

---@param plugin LazyPlugin
---@param is_dep? boolean
function Spec:add(plugin, is_dep)
  if not plugin.url and plugin[1] then
    plugin.url = Config.options.git.url_format:format(plugin[1])
  end

  if plugin.dir then
    plugin.dir = Util.norm(plugin.dir)
    -- local plugin
    plugin.name = plugin.name or Spec.get_name(plugin.dir)
  elseif plugin.url then
    plugin.name = plugin.name or Spec.get_name(plugin.url)
    -- check for dev plugins
    if plugin.dev == nil then
      for _, pattern in ipairs(Config.options.dev.patterns) do
        if plugin.url:find(pattern, 1, true) then
          plugin.dev = true
          break
        end
      end
    end
    -- dev plugins
    if plugin.dev then
      plugin.dir = Config.options.dev.path .. "/" .. plugin.name
    else
      -- remote plugin
      plugin.dir = Config.options.root .. "/" .. plugin.name
    end
  else
    self:error("Invalid plugin spec " .. vim.inspect(plugin))
  end

  plugin.event = type(plugin.event) == "string" and { plugin.event } or plugin.event
  plugin.keys = type(plugin.keys) == "string" and { plugin.keys } or plugin.keys
  plugin.cmd = type(plugin.cmd) == "string" and { plugin.cmd } or plugin.cmd
  plugin.ft = type(plugin.ft) == "string" and { plugin.ft } or plugin.ft

  plugin._ = {}
  plugin._.dep = is_dep

  local other = self.plugins[plugin.name]
  self.plugins[plugin.name] = other and self:merge(other, plugin) or plugin
  return self.plugins[plugin.name]
end

function Spec:error(msg)
  self:notify(msg, vim.log.levels.ERROR)
end

function Spec:warn(msg)
  self:notify(msg, vim.log.levels.WARN)
end

---@param msg string
---@param level number
function Spec:notify(msg, level)
  self.notifs[#self.notifs + 1] = { msg = msg, level = level, file = self.importing }
  Util.notify(msg, level)
end

---@param spec LazySpec|LazySpecImport
---@param results? string[]
---@param is_dep? boolean
function Spec:normalize(spec, results, is_dep)
  results = results or {}
  if type(spec) == "string" then
    if is_dep and not spec:find("/", 1, true) then
      -- spec is a plugin name
      table.insert(results, spec)
    else
      table.insert(results, self:add({ spec }, is_dep).name)
    end
  elseif #spec > 1 or Util.is_list(spec) then
    ---@cast spec LazySpec[]
    for _, s in ipairs(spec) do
      self:normalize(s, results, is_dep)
    end
  elseif spec.import then
    ---@cast spec LazySpecImport
    self:import(spec)
  else
    ---@cast spec LazyPluginSpec
    if spec.enabled == nil or spec.enabled == true or (type(spec.enabled) == "function" and spec.enabled()) then
      local plugin
      -- check if we already processed this spec. Can happen when a user uses the same instance of a spec in multiple specs
      -- see https://github.com/folke/lazy.nvim/issues/45
      if spec._ then
        plugin = spec
      else
        ---@cast spec LazyPlugin
        spec.dependencies = spec.dependencies and self:normalize(spec.dependencies, {}, true) or nil
        plugin = self:add(spec, is_dep)
      end
      table.insert(results, plugin.name)
    end
  end
  return results
end

---@param spec LazySpecImport
function Spec:import(spec)
  if spec.enabled == false or (type(spec.enabled) == "function" and not spec.enabled()) then
    return
  end

  Cache.indexed_unloaded = false

  local imported = 0
  Util.lsmod(spec.import, function(modname)
    imported = imported + 1
    Util.track({ import = modname })
    self.importing = modname
    -- unload the module so we get a clean slate
    ---@diagnostic disable-next-line: no-unknown
    package.loaded[modname] = nil
    Util.try(function()
      self:normalize(Cache.require(modname))
      self.modules[#self.modules + 1] = modname
      self.importing = nil
      Util.track()
    end, {
      msg = "Failed to load `" .. modname .. "`",
      on_error = function(msg)
        self:error(msg)
        self.importing = nil
        Util.track()
      end,
    })
  end)
  if imported == 0 then
    self:error("No specs found for module " .. spec.import)
  end
end

---@param old LazyPlugin
---@param new LazyPlugin
---@return LazyPlugin
function Spec:merge(old, new)
  local is_dep = old._.dep and new._.dep

  ---@diagnostic disable-next-line: no-unknown
  for k, v in pairs(new) do
    if k == "_" then
    elseif old[k] ~= nil and old[k] ~= v then
      if Handler.types[k] then
        local values = type(v) == "string" and { v } or v
        vim.list_extend(values, type(old[k]) == "string" and { old[k] } or old[k])
        ---@diagnostic disable-next-line: no-unknown
        old[k] = values
      elseif k == "config" or k == "priority" then
        old[k] = v
      elseif k == "dependencies" then
        for _, dep in ipairs(v) do
          if not vim.tbl_contains(old[k], dep) then
            table.insert(old[k], dep)
          end
        end
      else
        old[k] = v
        self:error("Merging plugins is not supported for key `" .. k .. "`\n" .. vim.inspect({ old = old, new = new }))
      end
    else
      ---@diagnostic disable-next-line: no-unknown
      old[k] = v
    end
  end
  old._.dep = is_dep
  return old
end

function M.update_state()
  ---@type table<string,FileType>
  local installed = {}
  Util.ls(Config.options.root, function(_, name, type)
    if type == "directory" and name ~= "readme" then
      installed[name] = type
    end
  end)

  for _, plugin in pairs(Config.plugins) do
    plugin._ = plugin._ or {}
    if plugin.lazy == nil then
      local lazy = plugin._.dep
        or Config.options.defaults.lazy
        or plugin.event
        or plugin.keys
        or plugin.ft
        or plugin.cmd
      plugin.lazy = lazy and true or false
    end
    if plugin.dir:find(Config.options.root, 1, true) == 1 then
      plugin._.installed = installed[plugin.name] ~= nil
      installed[plugin.name] = nil
    else
      plugin._.is_local = true
      plugin._.installed = true -- local plugins are managed by the user
    end
  end

  Config.to_clean = {}
  for pack, dir_type in pairs(installed) do
    table.insert(Config.to_clean, {
      name = pack,
      dir = Config.options.root .. "/" .. pack,
      _ = {
        kind = "clean",
        installed = true,
        is_symlink = dir_type == "link",
        is_local = dir_type == "link",
      },
    })
  end
end

function M.load()
  -- load specs
  Util.track("spec")
  Config.spec = Spec.new()
  Config.spec:normalize(vim.deepcopy(Config.options.spec))

  -- add ourselves
  Config.spec:add({ "folke/lazy.nvim" })
  -- override some lazy props
  local lazy = Config.spec.plugins["lazy.nvim"]
  lazy.lazy = true
  lazy.dir = Config.me
  lazy.config = function()
    error("lazy config should not be called")
  end
  lazy._.loaded = {}

  local existing = Config.plugins
  Config.plugins = Config.spec.plugins
  -- copy state. This wont do anything during startup
  for name, plugin in pairs(existing) do
    if Config.plugins[name] then
      Config.plugins[name]._ = plugin._
    end
  end
  Util.track()

  Util.track("state")
  M.update_state()
  Util.track()
  require("lazy.core.cache").indexed_unloaded = false
end

-- Finds the plugin that has this path
---@param path string
function M.find(path)
  local lua = path:find("/lua/", 1, true)
  if lua then
    local name = path:sub(1, lua - 1)
    local slash = name:reverse():find("/", 1, true)
    if slash then
      name = name:sub(#name - slash + 2)
      return name and Config.plugins[name] or nil
    end
  end
end

return M
