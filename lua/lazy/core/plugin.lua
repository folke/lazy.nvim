local Config = require("lazy.core.config")
local Util = require("lazy.core.util")
local Handler = require("lazy.core.handler")

---@class LazyCorePlugin
local M = {}
M.loading = false

---@class LazySpecLoader
---@field plugins table<string, LazyPlugin>
---@field disabled table<string, LazyPlugin>
---@field modules string[]
---@field notifs {msg:string, level:number, file?:string}[]
---@field importing? string
---@field optional? boolean
local Spec = {}
M.Spec = Spec

---@param spec? LazySpec
---@param opts? {optional?:boolean}
function Spec.new(spec, opts)
  local self = setmetatable({}, { __index = Spec })
  self.plugins = {}
  self.disabled = {}
  self.modules = {}
  self.notifs = {}
  self.optional = opts and opts.optional
  if spec then
    self:parse(spec)
  end
  return self
end

function Spec:parse(spec)
  self:normalize(spec)

  -- calculate handlers
  for _, plugin in pairs(self.plugins) do
    for _, handler in pairs(Handler.types) do
      if plugin[handler] then
        plugin[handler] = M.values(plugin, handler, true)
      end
    end
  end

  self:fix_disabled()
end

-- PERF: optimized code to get package name without using lua patterns
function Spec.get_name(pkg)
  local name = pkg:sub(-4) == ".git" and pkg:sub(1, -5) or pkg
  name = name:sub(-1) == "/" and name:sub(1, -2) or name
  local slash = name:reverse():find("/", 1, true) --[[@as number?]]
  return slash and name:sub(#name - slash + 2) or pkg:gsub("%W+", "_")
end

---@param plugin LazyPlugin
---@param results? string[]
---@param is_dep? boolean
function Spec:add(plugin, results, is_dep)
  -- check if we already processed this spec. Can happen when a user uses the same instance of a spec in multiple specs
  -- see https://github.com/folke/lazy.nvim/issues/45
  if rawget(plugin, "_") then
    if results then
      table.insert(results, plugin.name)
    end
    return plugin
  end

  local is_ref = plugin[1] and not plugin[1]:find("/", 1, true)

  if not plugin.url and not is_ref and plugin[1] then
    local prefix = plugin[1]:sub(1, 4)
    if prefix == "http" or prefix == "git@" then
      plugin.url = plugin[1]
    else
      plugin.url = Config.options.git.url_format:format(plugin[1])
    end
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
    if
      plugin.dev
      and (not Config.options.dev.fallback or vim.fn.isdirectory(Config.options.dev.path .. "/" .. plugin.name) == 1)
    then
      plugin.dir = Config.options.dev.path .. "/" .. plugin.name
    else
      -- remote plugin
      plugin.dir = Config.options.root .. "/" .. plugin.name
    end
  elseif is_ref then
    plugin.name = plugin[1]
  else
    self:error("Invalid plugin spec " .. vim.inspect(plugin))
    return
  end

  if not plugin.name or plugin.name == "" then
    self:error("Plugin spec " .. vim.inspect(plugin) .. " has no name")
    return
  end

  if type(plugin.config) == "table" then
    self:warn(
      "{" .. plugin.name .. "}: setting a table to `Plugin.config` is deprecated. Please use `Plugin.opts` instead"
    )
    ---@diagnostic disable-next-line: assign-type-mismatch
    plugin.opts = plugin.config
    plugin.config = nil
  end

  plugin._ = {}
  plugin._.dep = is_dep

  plugin.dependencies = plugin.dependencies and self:normalize(plugin.dependencies, {}, true) or nil
  if self.plugins[plugin.name] then
    plugin = self:merge(self.plugins[plugin.name], plugin)
  elseif is_ref and not plugin.url then
    self:error("Plugin spec for **" .. plugin.name .. "** not found.\n```lua\n" .. vim.inspect(plugin) .. "\n```")
    return
  end
  self.plugins[plugin.name] = plugin
  if results then
    table.insert(results, plugin.name)
  end
  return plugin
end

function Spec:error(msg)
  self:log(msg, vim.log.levels.ERROR)
end

function Spec:warn(msg)
  self:log(msg, vim.log.levels.WARN)
end

function Spec:fix_disabled()
  if not self.optional then
    ---@param plugin LazyPlugin
    local function all_optional(plugin)
      return (not plugin) or (rawget(plugin, "optional") and all_optional(plugin._.super))
    end

    -- handle optional plugins
    for _, plugin in pairs(self.plugins) do
      if plugin.optional and all_optional(plugin) then
        self.plugins[plugin.name] = nil
      end
    end
  end

  ---@type table<string,string[]> plugin to parent plugin
  local dep_of = {}

  ---@type string[] dependencies of disabled plugins
  local disabled_deps = {}

  for _, plugin in pairs(self.plugins) do
    local enabled = not (plugin.enabled == false or (type(plugin.enabled) == "function" and not plugin.enabled()))
    if enabled then
      for _, dep in ipairs(plugin.dependencies or {}) do
        dep_of[dep] = dep_of[dep] or {}
        table.insert(dep_of[dep], plugin.name)
      end
    else
      plugin._.kind = "disabled"
      self.plugins[plugin.name] = nil
      self.disabled[plugin.name] = plugin
      if plugin.dependencies then
        vim.list_extend(disabled_deps, plugin.dependencies)
      end
    end
  end

  -- check deps of disabled plugins
  for _, dep in ipairs(disabled_deps) do
    -- only check if the plugin is still enabled and it is a dep
    if self.plugins[dep] and self.plugins[dep]._.dep then
      -- check if the dep is still used by another plugin
      local keep = false
      for _, parent in ipairs(dep_of[dep] or {}) do
        if self.plugins[parent] then
          keep = true
          break
        end
      end
      -- disable the dep when no longer needed
      if not keep then
        local plugin = self.plugins[dep]
        plugin._.kind = "disabled"
        self.plugins[plugin.name] = nil
        self.disabled[plugin.name] = plugin
      end
    end
  end
end

---@param msg string
---@param level number
function Spec:log(msg, level)
  self.notifs[#self.notifs + 1] = { msg = msg, level = level, file = self.importing }
end

function Spec:report(level)
  level = level or vim.log.levels.ERROR
  for _, notif in ipairs(self.notifs) do
    if notif.level >= level then
      Util.notify(notif.msg, { level = notif.level })
    end
  end
end

---@param spec LazySpec|LazySpecImport
---@param results? string[]
---@param is_dep? boolean
function Spec:normalize(spec, results, is_dep)
  if type(spec) == "string" then
    if is_dep and not spec:find("/", 1, true) then
      -- spec is a plugin name
      if results then
        table.insert(results, spec)
      end
    else
      self:add({ spec }, results, is_dep)
    end
  elseif #spec > 1 or Util.is_list(spec) then
    ---@cast spec LazySpec[]
    for _, s in ipairs(spec) do
      self:normalize(s, results, is_dep)
    end
  elseif spec[1] or spec.dir or spec.url then
    ---@cast spec LazyPlugin
    local plugin = self:add(spec, results, is_dep)
    ---@diagnostic disable-next-line: cast-type-mismatch
    ---@cast plugin LazySpecImport
    if plugin and plugin.import then
      self:import(plugin)
    end
  elseif spec.import then
    ---@cast spec LazySpecImport
    self:import(spec)
  else
    self:error("Invalid plugin spec " .. vim.inspect(spec))
  end
  return results
end

---@param spec LazySpecImport
function Spec:import(spec)
  if spec.import == "lazy" then
    return self:error("You can't name your plugins module `lazy`.")
  end
  if type(spec.import) ~= "string" then
    return self:error("Invalid import spec. `import` should be a string: " .. vim.inspect(spec))
  end
  if vim.tbl_contains(self.modules, spec.import) then
    return
  end
  if spec.enabled == false or (type(spec.enabled) == "function" and not spec.enabled()) then
    return
  end

  self.modules[#self.modules + 1] = spec.import

  local imported = 0

  ---@type string[]
  local modnames = {}
  Util.lsmod(spec.import, function(modname)
    modnames[#modnames + 1] = modname
  end)
  table.sort(modnames)

  for _, modname in ipairs(modnames) do
    imported = imported + 1
    Util.track({ import = modname })
    self.importing = modname
    -- unload the module so we get a clean slate
    ---@diagnostic disable-next-line: no-unknown
    package.loaded[modname] = nil
    Util.try(function()
      local mod = require(modname)
      if type(mod) ~= "table" then
        self.importing = nil
        return self:error(
          "Invalid spec module: `"
            .. modname
            .. "`\nExpected a `table` of specs, but a `"
            .. type(mod)
            .. "` was returned instead"
        )
      end
      self:normalize(mod)
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
  end
  if imported == 0 then
    self:error("No specs found for module " .. spec.import)
  end
end

---@param old LazyPlugin
---@param new LazyPlugin
---@return LazyPlugin
function Spec:merge(old, new)
  new._.dep = old._.dep and new._.dep

  if new.url and old.url and new.url ~= old.url then
    self:error("Two plugins with the same name and different url:\n" .. vim.inspect({ old = old, new = new }))
  end

  if new.dependencies and old.dependencies then
    Util.extend(new.dependencies, old.dependencies)
  end

  new._.super = old
  setmetatable(new, { __index = old })

  return new
end

function M.update_state()
  ---@type string[]
  local cloning = {}

  ---@type table<string,FileType>
  local installed = {}
  Util.ls(Config.options.root, function(_, name, type)
    if type == "directory" and name ~= "readme" then
      installed[name] = type
    elseif type == "file" and name:sub(-8) == ".cloning" then
      name = name:sub(1, -9)
      cloning[#cloning + 1] = name
    end
  end)

  for _, failed in ipairs(cloning) do
    installed[failed] = nil
  end

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
  M.loading = true
  -- load specs
  Util.track("spec")
  Config.spec = Spec.new()
  Config.spec:parse({ vim.deepcopy(Config.options.spec), { "folke/lazy.nvim" } })

  -- override some lazy props
  local lazy = Config.spec.plugins["lazy.nvim"]
  if lazy then
    lazy.lazy = true
    lazy.dir = Config.me
    lazy.config = function()
      error("lazy config should not be called")
    end
    lazy._.loaded = {}
  end

  local existing = Config.plugins
  Config.plugins = Config.spec.plugins
  -- copy state. This wont do anything during startup
  for name, plugin in pairs(existing) do
    if Config.plugins[name] then
      local dep = Config.plugins[name]._.dep
      local super = Config.plugins[name]._.super
      Config.plugins[name]._ = plugin._
      Config.plugins[name]._.dep = dep
      Config.plugins[name]._.super = super
    end
  end
  Util.track()

  Util.track("state")
  M.update_state()
  Util.track()
  M.loading = false
  vim.api.nvim_exec_autocmds("User", { pattern = "LazyPlugins", modeline = false })
end

-- Finds the plugin that has this path
---@param path string
function M.find(path)
  if not Config.spec then
    return
  end
  local lua = path:find("/lua/", 1, true)
  if lua then
    local name = path:sub(1, lua - 1)
    local slash = name:reverse():find("/", 1, true)
    if slash then
      name = name:sub(#name - slash + 2)
      return name and Config.plugins[name] or Config.spec.plugins[name] or nil
    end
  end
end

---@param plugin LazyPlugin
function M.has_errors(plugin)
  for _, task in ipairs(plugin._.tasks or {}) do
    if task.error then
      return true
    end
  end
  return false
end

-- Merges super values or runs the values function to override values or return new ones
-- Used for opts, cmd, event, ft and keys
---@param plugin LazyPlugin
---@param prop string
---@param is_list? boolean
function M.values(plugin, prop, is_list)
  ---@type table
  local ret = plugin._.super and M.values(plugin._.super, prop, is_list) or {}
  local values = rawget(plugin, prop)

  if not values then
    return ret
  elseif type(values) == "function" then
    ret = values(plugin, ret) or ret
    return type(ret) == "table" and ret or { ret }
  end

  values = type(values) == "table" and values or { values }
  return is_list and Util.extend(ret, values) or Util.merge(ret, values)
end

return M
