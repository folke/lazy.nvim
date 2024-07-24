local Config = require("lazy.core.config")
local Meta = require("lazy.core.meta")
local Pkg = require("lazy.pkg")
local Util = require("lazy.core.util")

---@class LazyCorePlugin
local M = {}
M.loading = false

---@class LazySpecLoader
---@field meta LazyMeta
---@field plugins table<string, LazyPlugin>
---@field disabled table<string, LazyPlugin>
---@field ignore_installed table<string, true>
---@field modules string[]
---@field notifs {msg:string, level:number, file?:string}[]
---@field importing? string
---@field optional? boolean
local Spec = {}
M.Spec = Spec
M.LOCAL_SPEC = ".lazy.lua"

---@param spec? LazySpec
---@param opts? {optional?:boolean, pkg?:boolean}
function Spec.new(spec, opts)
  local self = setmetatable({}, Spec)
  self.meta = Meta.new(self)
  self.disabled = {}
  self.modules = {}
  self.notifs = {}
  self.ignore_installed = {}
  self.optional = opts and opts.optional
  if not (opts and opts.pkg == false) then
    self.meta:load_pkgs()
  end
  if spec then
    self:parse(spec)
  end
  return self
end

function Spec:__index(key)
  if Spec[key] then
    return Spec[key]
  end
  if key == "plugins" then
    self.meta:rebuild()
    return self.meta.plugins
  end
end

function Spec:parse(spec)
  self:normalize(spec)
  self.meta:resolve()
end

-- PERF: optimized code to get package name without using lua patterns
---@return string
function Spec.get_name(pkg)
  local name = pkg:sub(-4) == ".git" and pkg:sub(1, -5) or pkg
  name = name:sub(-1) == "/" and name:sub(1, -2) or name
  local slash = name:reverse():find("/", 1, true) --[[@as number?]]
  return slash and name:sub(#name - slash + 2) or pkg:gsub("%W+", "_")
end

function Spec:error(msg)
  self:log(msg, vim.log.levels.ERROR)
end

function Spec:warn(msg)
  self:log(msg, vim.log.levels.WARN)
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
function Spec:normalize(spec)
  if type(spec) == "string" then
    self.meta:add({ spec })
  elseif #spec > 1 or Util.is_list(spec) then
    ---@cast spec LazySpec[]
    for _, s in ipairs(spec) do
      self:normalize(s)
    end
  elseif spec[1] or spec.dir or spec.url then
    ---@cast spec LazyPluginSpec
    self.meta:add(spec)
    ---@diagnostic disable-next-line: cast-type-mismatch
    ---@cast spec LazySpecImport
    if spec and spec.import then
      self:import(spec)
    end
  elseif spec.import then
    ---@cast spec LazySpecImport
    self:import(spec)
  else
    self:error("Invalid plugin spec " .. vim.inspect(spec))
  end
end

---@param spec LazySpecImport
function Spec:import(spec)
  if spec.import == "lazy" then
    return self:error("You can't name your plugins module `lazy`.")
  end
  if type(spec.import) == "function" then
    if not spec.name then
      return self:error("Invalid import spec. Missing name: " .. vim.inspect(spec))
    end
  elseif type(spec.import) ~= "string" then
    return self:error("Invalid import spec. `import` should be a string: " .. vim.inspect(spec))
  end

  local import_name = spec.name or spec.import
  ---@cast import_name string

  if vim.tbl_contains(self.modules, import_name) then
    return
  end
  if spec.cond == false or (type(spec.cond) == "function" and not spec.cond()) then
    return
  end
  if spec.enabled == false or (type(spec.enabled) == "function" and not spec.enabled()) then
    return
  end

  self.modules[#self.modules + 1] = import_name

  local import = spec.import

  local imported = 0

  ---@type {modname: string, load: fun():(LazyPluginSpec?, string?)}[]
  local modspecs = {}

  if type(import) == "string" then
    Util.lsmod(import, function(modname, modpath)
      modspecs[#modspecs + 1] = {
        modname = modname,
        load = function()
          local mod, err = loadfile(modpath)
          if mod then
            return mod()
          else
            return nil, err
          end
        end,
      }
    end)
    table.sort(modspecs, function(a, b)
      return a.modname < b.modname
    end)
  else
    modspecs = { { modname = import_name, load = spec.import } }
  end

  for _, modspec in ipairs(modspecs) do
    imported = imported + 1
    local modname = modspec.modname
    Util.track({ import = modname })
    self.importing = modname
    -- unload the module so we get a clean slate
    ---@diagnostic disable-next-line: no-unknown
    package.loaded[modname] = nil
    Util.try(function()
      local mod, err = modspec.load()
      if err then
        self:error("Failed to load `" .. modname .. "`:\n" .. err)
      elseif type(mod) ~= "table" then
        return self:error(
          "Invalid spec module: `"
            .. modname
            .. "`\nExpected a `table` of specs, but a `"
            .. type(mod)
            .. "` was returned instead"
        )
      else
        self:normalize(mod)
      end
    end, {
      msg = "Failed to load `" .. modname .. "`",
      on_error = function(msg)
        self:error(msg)
      end,
    })
    self.importing = nil
    Util.track()
  end
  if imported == 0 then
    self:error("No specs found for module " .. vim.inspect(spec.import))
  end
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

  M.update_rocks_state()

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

function M.update_rocks_state()
  local root = Config.options.rocks.root
  ---@type table<string,string>
  local installed = {}
  Util.ls(root, function(_, name, type)
    if type == "directory" then
      installed[name] = name
    end
  end)

  for _, plugin in pairs(Config.plugins) do
    if plugin.build == "rockspec" or plugin.name == "hererocks" then
      plugin._.build = not installed[plugin.name]
    end
  end
end

---@return LazySpecImport?
function M.find_local_spec()
  if not Config.options.local_spec then
    return
  end
  local path = vim.uv.cwd()
  while path and path ~= "" do
    local file = path .. "/" .. M.LOCAL_SPEC
    if vim.fn.filereadable(file) == 1 then
      return {
        name = vim.fn.fnamemodify(file, ":~:."),
        import = function()
          local data = vim.secure.read(file)
          if data then
            return loadstring(data, M.LOCAL_SPEC)()
          end
          return {}
        end,
      }
    end
    local p = vim.fn.fnamemodify(path, ":h")
    if p == path then
      break
    end
    path = p
  end
end

function M.load()
  M.loading = true
  -- load specs
  Util.track("spec")
  Config.spec = Spec.new()

  local specs = {
    ---@diagnostic disable-next-line: param-type-mismatch
    vim.deepcopy(Config.options.spec),
  }
  specs[#specs + 1] = M.find_local_spec()
  specs[#specs + 1] = { "folke/lazy.nvim" }

  Config.spec:parse(specs)

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

  -- add hererocks when enabled and needed
  for _, plugin in pairs(Config.spec.plugins) do
    if plugin.build == "rockspec" then
      if Config.hererocks() then
        Config.spec.meta:add({
          "luarocks/hererocks",
          build = "rockspec",
          lazy = true,
        })
      end
      break
    end
  end

  local existing = Config.plugins
  Config.plugins = Config.spec.plugins
  -- copy state. This wont do anything during startup
  for name, plugin in pairs(existing) do
    if Config.plugins[name] then
      local new_state = Config.plugins[name]._
      Config.plugins[name]._ = plugin._
      Config.plugins[name]._.dep = new_state.dep
      Config.plugins[name]._.frags = new_state.frags
      Config.plugins[name]._.pkg = new_state.pkg
    end
  end
  Util.track()

  Util.track("state")
  M.update_state()
  Util.track()

  if Config.options.pkg.enabled and Pkg.dirty then
    Pkg.update()
    return M.load()
  end

  M.loading = false
  vim.api.nvim_exec_autocmds("User", { pattern = "LazyPlugins", modeline = false })
end

-- Finds the plugin that has this path
---@param path string
---@param opts? {fast?:boolean}
function M.find(path, opts)
  if not Config.spec then
    return
  end
  opts = opts or {}
  local lua = path:find("/lua/", 1, true)
  if lua then
    local name = path:sub(1, lua - 1)
    local slash = name:reverse():find("/", 1, true)
    if slash then
      name = name:sub(#name - slash + 2)
      if name then
        if opts.fast then
          return Config.spec.meta.plugins[name]
        end
        return Config.spec.plugins[name]
      end
    end
  end
end

---@param plugin LazyPlugin
function M.has_errors(plugin)
  for _, task in ipairs(plugin._.tasks or {}) do
    if task:has_errors() then
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
  local super = getmetatable(plugin)
  ---@type table
  local ret = super and M._values(root, super.__index, prop, is_list) or {}
  local values = rawget(plugin, prop)

  if not values then
    return ret
  elseif type(values) == "function" then
    ret = values(root, ret) or ret
    return type(ret) == "table" and ret or { ret }
  end

  values = type(values) == "table" and values or { values }
  if is_list then
    return Util.extend(ret, values)
  else
    ---@type {path:string[], list:any[]}[]
    local lists = {}
    ---@diagnostic disable-next-line: no-unknown
    for _, key in ipairs(plugin[prop .. "_extend"] or {}) do
      local path = vim.split(key, ".", { plain = true })
      local r = Util.key_get(ret, path)
      local v = Util.key_get(values, path)
      if type(r) == "table" and type(v) == "table" then
        lists[key] = { path = path, list = {} }
        vim.list_extend(lists[key].list, r)
        vim.list_extend(lists[key].list, v)
      end
    end
    local t = Util.merge(ret, values)
    for _, list in pairs(lists) do
      Util.key_set(t, list.path, list.list)
    end
    return t
  end
end

return M
