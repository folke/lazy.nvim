local Config = require("lazy.core.config")
local Util = require("lazy.core.util")
local Handler = require("lazy.core.handler")

local M = {}

---@class LazyPluginState
---@field loaded? {[string]:string}|{time:number}
---@field installed boolean
---@field tasks? LazyTask[]
---@field dirty? boolean
---@field updated? {from:string, to:string}
---@field is_local boolean
---@field has_updates? boolean
---@field cloned? boolean
---@field dep? boolean True if this plugin is only in the spec as a dependency

---@class LazyPluginHooks
---@field init? fun(LazyPlugin) Will always be run
---@field config? fun(LazyPlugin) Will be executed when loading the plugin
---@field build? string|fun(LazyPlugin)

---@class LazyPluginHandlers: table<LazyHandlerTypes, string|string[]>
---@field event? string|string[]
---@field cmd? string|string[]
---@field ft? string|string[]
---@field keys? string|string[]

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
---@field enabled? boolean|(fun():boolean)
---@field lazy? boolean
---@field dev? boolean If set, then link to the respective folder under your ~/projects
---@field dependencies? string[]
---@field _ LazyPluginState

---@alias LazySpec string|LazyPlugin|LazyPlugin[]|{dependencies:LazySpec}

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
    elseif c == "/" or pkg:sub(1, 4) == "http" or pkg:sub(1, 3) == "ssh" then
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

  plugin._ = {}
  plugin._.dep = is_dep

  -- check for plugins that should be local
  for _, pattern in ipairs(Config.options.dev.patterns) do
    if plugin.dev or (plugin[1]:find(pattern, 1, true) and plugin.dev ~= false) then
      plugin.uri = Config.options.dev.path .. "/" .. plugin.name
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
      else
        error("Merging plugins is not supported for key `" .. k .. "`")
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
    if type == "directory" or type == "link" then
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
    if plugin.uri:sub(1, 4) ~= "http" and plugin.uri:sub(1, 3) ~= "git" then
      plugin._.is_local = true
      plugin.dir = plugin.uri
      plugin._.installed = true -- user should make sure the directory exists
    else
      plugin.dir = Config.options.root .. "/" .. plugin.name
      plugin._.installed = installed[plugin.name] ~= nil
      installed[plugin.name] = nil
    end
  end

  Config.to_clean = {}
  for pack, dir_type in pairs(installed) do
    table.insert(Config.to_clean, {
      name = pack,
      dir = Config.options.root .. "/" .. pack,
      _ = {
        installed = true,
        is_symlink = dir_type == "link",
        is_local = dir_type == "link",
      },
    })
  end
end

function M.spec()
  local spec = Spec.new()

  if type(Config.spec) == "string" then
    -- spec is a module
    local function _load(name)
      local modname = name and (Config.spec .. "." .. name) or Config.spec
      -- unload the module so we get a clean slate
      ---@diagnostic disable-next-line: no-unknown
      package.loaded[modname] = nil
      Util.try(function()
        spec:normalize(require(modname))
      end, "Failed to load **" .. modname .. "**")
    end
    local path_plugins = vim.fn.stdpath("config") .. "/lua/" .. Config.spec:gsub("%.", "/")

    _load()
    Util.lsmod(path_plugins, _load)
  else
    -- spec is a spec
    spec:normalize(Config.spec)
  end
  return spec
end

function M.load()
  -- load specs
  Util.track("spec")
  local spec = M.spec()

  -- add ourselves
  spec.plugins["lazy.nvim"] = nil
  spec:add({ "folke/lazy.nvim", lazy = true })

  local existing = Config.plugins
  Config.plugins = spec.plugins
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
end

-- Finds the plugin that has this path
---@param path string
function M.find(path)
  local name = path:match("/([^/]+)/lua") or path:match("/([^/]+)/?$")
  return name and Config.plugins[name] or nil
end

return M
