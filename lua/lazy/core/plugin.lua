local Config = require("lazy.core.config")
local Util = require("lazy.core.util")
local Handler = require("lazy.core.handler")
local Cache = require("lazy.core.cache")

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
---@field event? string[]
---@field cmd? string[]
---@field ft? string[]
---@field keys? string[]
---@field module? false

---@class LazyPluginRef
---@field branch? string
---@field tag? string
---@field commit? string
---@field version? string
---@field pin? boolean

---@class LazyPlugin: LazyPluginHandlers,LazyPluginHooks,LazyPluginRef
---@field [1] string?
---@field name string display name and name used for plugin config files
---@field url string?
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
    Util.error("Invalid plugin spec " .. vim.inspect(plugin))
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
    local plugin
    -- check if we already processed this spec. Can happen when a user uses the same instance of a spec in multiple specs
    -- see https://github.com/folke/lazy.nvim/issues/45
    if spec._ then
      plugin = spec
    else
      ---@cast spec LazyPlugin
      plugin = self:add(spec, is_dep)
      plugin.dependencies = plugin.dependencies and self:normalize(plugin.dependencies, {}, true) or nil
    end
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
        Util.error("Merging plugins is not supported for key `" .. k .. "`\n" .. vim.inspect({ old = old, new = new }))
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
        or plugin.init
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
    local function _load(modname)
      -- unload the module so we get a clean slate
      ---@diagnostic disable-next-line: no-unknown
      package.loaded[modname] = nil
      Util.try(function()
        spec:normalize(Cache.require(modname))
      end, "Failed to load **" .. modname .. "**")
    end
    Util.lsmod(Config.spec --[[@as string]], _load)
  else
    -- spec is a spec
    spec:normalize(vim.deepcopy(Config.spec))
  end
  return spec
end

function M.load()
  -- load specs
  Util.track("spec")
  local spec = M.spec()

  -- add ourselves
  spec.plugins["lazy.nvim"] = nil
  spec:add({ "folke/lazy.nvim", lazy = true, dir = Config.me })

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
  local lua = path:find("/lua", 1, true)
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
