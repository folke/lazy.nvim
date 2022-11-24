local Cache = require("lazy.core.cache")
local Module = require("lazy.core.module")

local M = {}

M.dirty = true

function M.update_state(check_clean)
  local Util = require("lazy.core.util")
  local Config = require("lazy.core.config")
  ---@type table<"opt"|"start", table<string,boolean>>
  local installed = { opt = {}, start = {} }
  for opt, packs in pairs(installed) do
    Util.scandir(Config.options.package_path .. "/" .. opt, function(_, name, type)
      if type == "directory" or type == "link" then
        packs[name] = true
      end
    end)
  end

  for _, plugin in pairs(Config.plugins) do
    local opt = plugin.opt and "opt" or "start"
    plugin.installed = installed[opt][plugin.pack] == true
    installed[opt][plugin.pack] = nil
  end

  if check_clean then
    Config.to_clean = {}
    for opt, packs in pairs(installed) do
      for pack in pairs(packs) do
        table.insert(Config.to_clean, {
          name = pack,
          pack = pack,
          dir = Config.options.package_path .. "/" .. opt .. "/" .. pack,
          opt = opt == "opt",
          installed = true,
        })
      end
    end
  end
end

function M.save()
  if not M.dirty then
    return
  end
  local Config = require("lazy.core.config")

  ---@class LazyState
  local state = {
    ---@type CachedPlugin[]
    plugins = {},
    loaders = require("lazy.core.loader").loaders,
    config = Config.options,
  }

  ---@alias CachedPlugin LazyPlugin | {_funcs: table<string, number|boolean>}
  local skip = { installed = true, loaded = true, tasks = true, dirty = true, dir = true }
  local funcount = 0

  for _, plugin in pairs(Config.plugins) do
    ---@type CachedPlugin
    local save = {}
    table.insert(state.plugins, save)
    ---@diagnostic disable-next-line: no-unknown
    for k, v in pairs(plugin) do
      if type(v) == "function" then
        save._funcs = save._funcs or {}
        if plugin.modname then
          save._funcs[k] = true
        else
          funcount = funcount + 1
          Cache.set("cache.state.fun." .. funcount, string.dump(v))
          save._funcs[k] = funcount
        end
      elseif not skip[k] then
        save[k] = v
      end
    end
  end
  Cache.set("cache.state", vim.json.encode(state))
end

function M.load()
  ---@type boolean, LazyState
  local ok, state = pcall(vim.json.decode, Cache.get("cache.state"))
  if not ok then
    Cache.dirty()
    return false
  end

  local Config = require("lazy.core.config")

  if not vim.deep_equal(Config.options, state.config) then
    Cache.dirty()
    return false
  end

  if Module.is_dirty(Config.options.plugins, Config.paths.main) then
    return false
  end

  -- plugins
  for _, plugin in ipairs(state.plugins) do
    Config.plugins[plugin.name] = plugin
    plugin.loaded = nil
    plugin.dir = Config.options.package_path .. "/" .. (plugin.opt and "opt" or "start") .. "/" .. plugin.pack
    if plugin.modname then
      if Module.is_dirty(plugin.modname, plugin.modpath) then
        return false
      end
      for fun in pairs(plugin._funcs or {}) do
        ---@diagnostic disable-next-line: assign-type-mismatch
        plugin[fun] = function(...)
          local mod = Module.load(plugin.modname, plugin.modpath)
          for k in pairs(plugin._funcs) do
            plugin[k] = mod[k]
          end
          return plugin[fun](...)
        end
      end
    elseif plugin._funcs then
      for fun, id in pairs(plugin._funcs) do
        local chunk = assert(Cache.get("cache.state.fun." .. id))
        ---@diagnostic disable-next-line: assign-type-mismatch
        plugin[fun] = function(...)
          ---@diagnostic disable-next-line: assign-type-mismatch
          plugin[fun] = loadstring(chunk)
          return plugin[fun](...)
        end
      end
    end
  end
  M.update_state()

  -- loaders
  require("lazy.core.loader").loaders = state.loaders

  M.dirty = false

  return true
end

return M
