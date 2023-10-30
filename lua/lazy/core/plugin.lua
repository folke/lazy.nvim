local Config = require("lazy.core.config")
local Handler = require("lazy.core.handler")
local Util = require("lazy.core.util")

---@class LazyCorePlugin
local M = {}
M.loading = false

---@class LazySpecLoader
---@field plugins table<string, LazyPlugin>
---@field fragments table<number, LazyPlugin>
---@field disabled table<string, LazyPlugin>
---@field dirty table<string, true>
---@field ignore_installed table<string, true>
---@field modules string[]
---@field notifs {msg:string, level:number, file?:string}[]
---@field importing? string
---@field optional? boolean
local Spec = {}
M.Spec = Spec
M.last_fid = 0
M.fid_stack = {} ---@type number[]

---@param spec? LazySpec
---@param opts? {optional?:boolean}
function Spec.new(spec, opts)
  local self = setmetatable({}, { __index = Spec })
  self.plugins = {}
  self.fragments = {}
  self.disabled = {}
  self.modules = {}
  self.dirty = {}
  self.notifs = {}
  self.ignore_installed = {}
  self.optional = opts and opts.optional
  if spec then
    self:parse(spec)
  end
  return self
end

function Spec:parse(spec)
  self:normalize(spec)
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
function Spec:add(plugin, results)
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

  ---@type string?
  local dir

  if plugin.dir then
    dir = Util.norm(plugin.dir)
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

  -- dev plugins
  if plugin.dev then
    local dir_dev
    if type(Config.options.dev.path) == "string" then
      dir_dev = Config.options.dev.path .. "/" .. plugin.name
    else
      dir_dev = Util.norm(Config.options.dev.path(plugin))
    end
    if not Config.options.dev.fallback or vim.fn.isdirectory(dir_dev) == 1 then
      dir = dir_dev
    end
  elseif plugin.dev == false then
    -- explicitely select the default path
    dir = Config.options.root .. "/" .. plugin.name
  end

  if type(plugin.config) == "table" then
    self:warn(
      "{" .. plugin.name .. "}: setting a table to `Plugin.config` is deprecated. Please use `Plugin.opts` instead"
    )
    ---@diagnostic disable-next-line: assign-type-mismatch
    plugin.opts = plugin.config
    plugin.config = nil
  end

  local fpid = M.fid_stack[#M.fid_stack]

  M.last_fid = M.last_fid + 1
  plugin._ = {
    dir = dir,
    fid = M.last_fid,
    fpid = fpid,
    dep = fpid ~= nil,
    module = self.importing,
  }
  self.fragments[plugin._.fid] = plugin
  -- remote plugin
  plugin.dir = plugin._.dir or (plugin.name and (Config.options.root .. "/" .. plugin.name)) or nil

  if fpid then
    local parent = self.fragments[fpid]
    parent._.fdeps = parent._.fdeps or {}
    table.insert(parent._.fdeps, plugin._.fid)
  end

  if plugin.dependencies then
    table.insert(M.fid_stack, plugin._.fid)
    plugin.dependencies = self:normalize(plugin.dependencies, {})
    table.remove(M.fid_stack)
  end

  if self.plugins[plugin.name] then
    plugin = self:merge(self.plugins[plugin.name], plugin)
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

--- Rebuilds a plugin spec excluding any removed fragments
---@param name? string
function Spec:rebuild(name)
  if not name then
    for n, _ in pairs(self.dirty) do
      self:rebuild(n)
    end
    self.dirty = {}
  end
  local plugin = self.plugins[name]
  if not plugin then
    return
  end

  local fragments = {} ---@type LazyPlugin[]

  repeat
    local super = plugin._.super
    if self.fragments[plugin._.fid] then
      plugin._.dep = plugin._.fpid ~= nil
      plugin._.super = nil
      if plugin._.fdeps then
        plugin.dependencies = {}
        for _, cid in ipairs(plugin._.fdeps) do
          if self.fragments[cid] then
            table.insert(plugin.dependencies, self.fragments[cid].name)
          end
        end
      end
      setmetatable(plugin, nil)
      table.insert(fragments, 1, plugin)
    end
    plugin = super
  until not plugin

  if #fragments == 0 then
    self.plugins[name] = nil
    return
  end

  plugin = fragments[1]
  for i = 2, #fragments do
    plugin = self:merge(plugin, fragments[i])
  end
  self.plugins[name] = plugin
end

--- Recursively removes all fragments from a plugin spec or a given fragment
---@param id string|number Plugin name or fragment id
---@param opts {self: boolean}
function Spec:remove_fragments(id, opts)
  local fids = {} ---@type number[]

  if type(id) == "number" then
    fids[1] = id
  else
    local plugin = self.plugins[id]
    repeat
      fids[#fids + 1] = plugin._.fid
      plugin = plugin._.super
    until not plugin
  end

  for _, fid in ipairs(fids) do
    local fragment = self.fragments[fid]
    if fragment then
      for _, cid in ipairs(fragment._.fdeps or {}) do
        self:remove_fragments(cid, { self = true })
      end
      if opts.self then
        self.fragments[fid] = nil
      end
      self.dirty[fragment.name] = true
    end
  end
end

function Spec:fix_cond()
  for _, plugin in pairs(self.plugins) do
    local cond = plugin.cond
    if cond == nil then
      cond = Config.options.defaults.cond
    end
    if cond == false or (type(cond) == "function" and not cond(plugin)) then
      plugin._.cond = false
      local stack = { plugin }
      while #stack > 0 do
        local p = table.remove(stack)
        if not self.ignore_installed[p.name] then
          for _, dep in ipairs(p.dependencies or {}) do
            table.insert(stack, self.plugins[dep])
          end
          self.ignore_installed[p.name] = true
        end
      end
      plugin.enabled = false
    end
  end
end

function Spec:fix_optional()
  if not self.optional then
    ---@param plugin LazyPlugin
    local function all_optional(plugin)
      return (not plugin) or (rawget(plugin, "optional") and all_optional(plugin._.super))
    end

    -- handle optional plugins
    for _, plugin in pairs(self.plugins) do
      if plugin.optional and all_optional(plugin) then
        -- remove all optional fragments
        self:remove_fragments(plugin.name, { self = true })
        self.plugins[plugin.name] = nil
      end
    end
  end
end

function Spec:fix_disabled()
  for _, plugin in pairs(self.plugins) do
    if not plugin.name or not plugin.dir then
      self:error("Plugin spec for **" .. plugin.name .. "** not found.\n```lua\n" .. vim.inspect(plugin) .. "\n```")
      self.plugins[plugin.name] = nil
    end
  end

  self:fix_optional()
  self:rebuild()

  self:fix_cond()
  self:rebuild()

  self.dirty = {}

  for _, plugin in pairs(self.plugins) do
    local disabled = plugin.enabled == false or (type(plugin.enabled) == "function" and not plugin.enabled())
    if disabled then
      plugin._.kind = "disabled"
      -- remove all child fragments
      self:remove_fragments(plugin.name, { self = false })
      self.plugins[plugin.name] = nil
      self.disabled[plugin.name] = plugin
    end
  end

  -- rebuild any plugin specs that were modified
  self:rebuild()
end

---@param msg string
---@param level number
function Spec:log(msg, level)
  self.notifs[#self.notifs + 1] = { msg = msg, level = level, file = self.importing }
end

function Spec:report(level)
  level = level or vim.log.levels.ERROR
  local count = 0
  for _, notif in ipairs(self.notifs) do
    if notif.level >= level then
      Util.notify(notif.msg, { level = notif.level })
      count = count + 1
    end
  end
  return count
end

---@param spec LazySpec|LazySpecImport
---@param results? string[]
function Spec:normalize(spec, results)
  if type(spec) == "string" then
    if not spec:find("/", 1, true) then
      -- spec is a plugin name
      if results then
        table.insert(results, spec)
      end
    else
      self:add({ spec }, results)
    end
  elseif #spec > 1 or Util.is_list(spec) then
    ---@cast spec LazySpec[]
    for _, s in ipairs(spec) do
      self:normalize(s, results)
    end
  elseif spec[1] or spec.dir or spec.url then
    ---@cast spec LazyPlugin
    local plugin = self:add(spec, results)
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
  if spec.cond == false or (type(spec.cond) == "function" and not spec.cond()) then
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
    self:warn("Two plugins with the same name and different url:\n" .. vim.inspect({ old = old, new = new }))
  end

  if new.dependencies and old.dependencies then
    Util.extend(new.dependencies, old.dependencies)
  end

  local new_dir = new._.dir or old._.dir or (new.name and (Config.options.root .. "/" .. new.name)) or nil
  if new_dir ~= old.dir then
    local msg = "Plugin `" .. new.name .. "` changed `dir`:\n- from: `" .. old.dir .. "`\n- to: `" .. new_dir .. "`"
    if new._.rtp_loaded or old._.rtp_loaded then
      msg = msg
        .. "\n\nThis plugin was already partially loaded, so we did not change it's `dir`.\nPlease fix your config."
      self:error(msg)
      new_dir = old.dir
    else
      self:warn(msg)
    end
  end
  new.dir = new_dir
  new._.rtp_loaded = new._.rtp_loaded or old._.rtp_loaded

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

  for name in pairs(Config.spec.ignore_installed) do
    installed[name] = nil
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

-- Merges super values or runs the values function to override values or return new ones.
-- Values are cached for performance.
-- Used for opts, cmd, event, ft and keys
---@param plugin LazyPlugin
---@param prop string
---@param is_list? boolean
function M.values(plugin, prop, is_list)
  if not plugin[prop] then
    return {}
  end
  plugin._.cache = plugin._.cache or {}
  local key = prop .. (is_list and "_list" or "")
  if plugin._.cache[key] == nil then
    plugin._.cache[key] = M._values(plugin, plugin, prop, is_list)
  end
  return plugin._.cache[key]
end

-- Merges super values or runs the values function to override values or return new ones
-- Used for opts, cmd, event, ft and keys
---@param root LazyPlugin
---@param plugin LazyPlugin
---@param prop string
---@param is_list? boolean
function M._values(root, plugin, prop, is_list)
  if not plugin[prop] then
    return {}
  end
  ---@type table
  local ret = plugin._.super and M._values(root, plugin._.super, prop, is_list) or {}
  local values = rawget(plugin, prop)

  if not values then
    return ret
  elseif type(values) == "function" then
    ret = values(root, ret) or ret
    return type(ret) == "table" and ret or { ret }
  end

  values = type(values) == "table" and values or { values }
  return is_list and Util.extend(ret, values) or Util.merge(ret, values)
end

return M
