local Config = require("lazy.core.config")
local Util = require("lazy.core.util")

--- This class is used to manage the plugins.
--- A plugin is a collection of fragments that are related to each other.
---@class LazyMeta
---@field plugins table<string, LazyPlugin>
---@field str_to_meta table<string, LazyPlugin>
---@field frag_to_meta table<number, LazyPlugin>
---@field dirty table<string, boolean>
---@field spec LazySpecLoader
---@field fragments LazyFragments
local M = {}

---@param spec LazySpecLoader
---@return LazyMeta
function M.new(spec)
  local self = setmetatable({}, { __index = M })
  self.spec = spec
  self.fragments = require("lazy.core.fragments").new(spec)
  self.plugins = {}
  self.frag_to_meta = {}
  self.str_to_meta = {}
  self.dirty = {}
  return self
end

--- Remove a plugin and all its fragments.
---@param name string
function M:del(name)
  local meta = self.plugins[name]
  if not meta then
    return
  end
  for _, fid in ipairs(meta._.frags or {}) do
    self.fragments:del(fid)
  end
  self.plugins[name] = nil
end

--- Add a fragment to a plugin.
--- This will create a new plugin if it does not exist.
--- It also keeps track of renames.
---@param plugin LazyPluginSpec
function M:add(plugin)
  local fragment = self.fragments:add(plugin)
  if not fragment then
    return
  end

  local meta = self.plugins[fragment.name]
    or fragment.url and self.str_to_meta[fragment.url]
    or fragment.dir and self.str_to_meta[fragment.dir]

  if not meta then
    meta = { name = fragment.name, _ = { frags = {} } }
    local url, dir = fragment.url, fragment.dir
    -- add to index
    if url then
      self.str_to_meta[url] = meta
    end
    if dir then
      self.str_to_meta[dir] = meta
    end
  end

  table.insert(meta._.frags, fragment.id)

  if meta._ and meta._.rtp_loaded then
    local old_dir = meta.dir
    self:_rebuild(meta.name)
    local new_dir = meta.dir
    if old_dir ~= new_dir then
      local msg = "Plugin `" .. meta.name .. "` changed `dir`:\n- from: `" .. old_dir .. "`\n- to: `" .. new_dir .. "`"
      msg = msg .. "\n\nThis plugin was already partially loaded, so things may break.\nPlease fix your config."
      self.spec:error(msg)
    end
  end

  if plugin.name then
    -- handle renames
    if meta.name ~= plugin.name then
      self.plugins[meta.name] = nil
      meta.name = plugin.name
    end
  end

  self.plugins[meta.name] = meta
  self.frag_to_meta[fragment.id] = meta
  self.dirty[meta.name] = true
end

--- Rebuild all plugins based on dirty fragments,
--- or dirty plugins. Will remove plugins that no longer have fragments.
function M:rebuild()
  for fid in pairs(self.fragments.dirty) do
    local meta = self.frag_to_meta[fid]
    if meta then
      if self.fragments:get(fid) then
        -- fragment still exists, so mark plugin as dirty
        self.dirty[meta.name] = true
      else
        -- fragment was deleted, so remove it from plugin
        ---@param f number
        meta._.frags = vim.tbl_filter(function(f)
          return f ~= fid
        end, meta._.frags)
        -- if no fragments left, delete plugin
        if #meta._.frags == 0 then
          self:del(meta.name)
        else
          self.dirty[meta.name] = true
        end
      end
    end
  end
  self.fragments.dirty = {}
  for n, _ in pairs(self.dirty) do
    self:_rebuild(n)
  end
end

--- Rebuild a single plugin.
--- This will resolve the plugin based on its fragments using metatables.
--- This also resolves dependencies, dep, optional, dir, dev, and url.
---@param name string
function M:_rebuild(name)
  local plugin = self.plugins[name]
  if not plugin or #plugin._.frags == 0 then
    self.plugins[name] = nil
    return
  end
  setmetatable(plugin, nil)
  plugin.dependencies = {}

  local super = nil
  plugin.url = nil
  plugin._.dep = true
  plugin.optional = true

  assert(#plugin._.frags > 0, "no fragments found for plugin " .. name)

  for _, fid in ipairs(plugin._.frags) do
    local fragment = self.fragments:get(fid)
    assert(fragment, "fragment " .. fid .. " not found, for plugin " .. name)
    ---@diagnostic disable-next-line: no-unknown
    super = setmetatable(fragment.spec, super and { __index = super } or nil)
    plugin._.dep = plugin._.dep and fragment.dep
    plugin.optional = plugin.optional and (rawget(fragment.spec, "optional") == true)
    plugin.url = fragment.url or plugin.url

    -- dependencies
    for _, dep in ipairs(fragment.deps or {}) do
      table.insert(plugin.dependencies, self.fragments:get(dep).name)
    end
  end

  super = super or {}

  -- dir / dev
  plugin.dev = super.dev
  plugin.dir = super.dir
  if plugin.dir then
    plugin.dir = Util.norm(plugin.dir)
  else
    if plugin.dev == nil and plugin.url then
      for _, pattern in ipairs(Config.options.dev.patterns) do
        if plugin.url:find(pattern, 1, true) then
          plugin.dev = true
          break
        end
      end
    end
    if plugin.dev == true then
      local dev_dir = type(Config.options.dev.path) == "string" and Config.options.dev.path .. "/" .. plugin.name
        or Util.norm(Config.options.dev.path(plugin))
      if not Config.options.dev.fallback or vim.fn.isdirectory(dev_dir) == 1 then
        plugin.dir = dev_dir
      else
        plugin.dev = false
      end
    end
    plugin.dir = plugin.dir or Config.options.root .. "/" .. plugin.name
  end

  -- dependencies
  if #plugin.dependencies == 0 and not super.dependencies then
    plugin.dependencies = nil
  end

  -- optional
  if not plugin.optional and not super.optional then
    plugin.optional = nil
  end

  setmetatable(plugin, { __index = super })

  self.dirty[plugin.name] = nil
  return plugin
end

--- Disable a plugin.
---@param plugin LazyPlugin
function M:disable(plugin)
  plugin._.kind = "disabled"
  self:del(plugin.name)
  self.spec.disabled[plugin.name] = plugin
end

--- Check if a plugin should be disabled, but ignore uninstalling it.
function M:fix_cond()
  for _, plugin in pairs(self.plugins) do
    local cond = plugin.cond
    if cond == nil then
      cond = Config.options.defaults.cond
    end
    if cond == false or (type(cond) == "function" and not cond(plugin)) then
      plugin._.cond = false
      local stack = { plugin }
      while #stack > 0 do
        local p = table.remove(stack) --[[@as LazyPlugin]]
        if not self.spec.ignore_installed[p.name] then
          for _, dep in ipairs(p.dependencies or {}) do
            table.insert(stack, self.plugins[dep])
          end
          self.spec.ignore_installed[p.name] = true
        end
      end
      plugin.enabled = false
    end
  end
end

--- Removes plugins for which all its fragments are optional.
function M:fix_optional()
  if self.spec.optional then
    return 0
  end
  local changes = 0
  for _, plugin in pairs(self.plugins) do
    if plugin.optional then
      changes = changes + 1
      self:del(plugin.name)
    end
  end
  self:rebuild()
  return changes
end

--- Removes plugins that are disabled.
function M:fix_disabled()
  local changes = 0
  for _, plugin in pairs(self.plugins) do
    if plugin.enabled == false or (type(plugin.enabled) == "function" and not plugin.enabled()) then
      changes = changes + 1
      self:disable(plugin)
    end
  end
  self:rebuild()
  return changes
end

--- Resolve all plugins, based on cond, enabled and optional.
function M:resolve()
  Util.track("resolve plugins")
  self:rebuild()

  self:fix_cond()

  -- selene: allow(empty_loop)
  while self:fix_disabled() + self:fix_optional() > 0 do
  end
  Util.track()
end

return M
