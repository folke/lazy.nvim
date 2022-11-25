local Cache = require("lazy.core.cache")
local Module = require("lazy.core.module")
local Config = require("lazy.core.config")

local M = {}

M.dirty = true

---@alias CachedPlugin LazyPlugin | {_funs: string[]}
local skip = { installed = true, loaded = true, tasks = true, dirty = true, dir = true }
local funs = { config = true, init = true, run = true }

function M.update_state(check_clean)
  local Util = require("lazy.core.util")

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
    plugin.opt = plugin.opt == nil and Config.options.opt or plugin.opt
    local opt = plugin.opt and "opt" or "start"
    plugin.dir = Config.options.package_path .. "/" .. opt .. "/" .. plugin.name
    plugin.installed = installed[opt][plugin.name] == true
    installed[opt][plugin.name] = nil
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
  local Plugin = require("lazy.plugin")

  ---@class LazyState
  local state = {
    ---@type table<string, LazySpec>
    specs = {},
    loaders = require("lazy.core.loader").loaders,
    config = Config.options,
  }

  for _, spec in ipairs(Plugin.specs()) do
    state.specs[spec.modname] = spec
    for _, plugin in pairs(spec.plugins) do
      ---@cast plugin CachedPlugin
      for k, v in pairs(plugin) do
        if type(v) == "function" then
          if funs[k] then
            plugin._funs = plugin._funs or {}
            table.insert(plugin._funs, k)
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

function M.load()
  local Plugin = require("lazy.plugin")
  local dirty = false

  ---@type boolean, LazyState?
  local ok, state = pcall(vim.json.decode, Cache.get("cache.state"))
  if not (ok and state and vim.deep_equal(Config.options, state.config)) then
    dirty = true
    state = nil
  end

  local function _loader(modname, modpath)
    local spec = state and state.specs[modname]
    if (not spec) or Module.is_dirty(modname, modpath) then
      dirty = true
      vim.schedule(function()
        vim.notify("Reloading " .. modname)
      end)
      return Plugin.Spec.load(modname, modpath)
    end
    ---@type LazySpec
    local loaded = nil

    for name, plugin in pairs(spec.plugins) do
      ---@cast plugin CachedPlugin
      for _, fun in ipairs(plugin._funs or {}) do
        plugin[fun] = function(...)
          loaded = loaded or Plugin.Spec.load(spec.modname, spec.modpath)
          return loaded.plugins[name][fun](...)
        end
      end
    end
    return spec
  end

  Plugin.load(_loader)

  if state and not dirty then
    require("lazy.core.loader").loaders = state.loaders
  else
    Cache.dirty()
  end

  M.dirty = dirty
  return not dirty
end

return M
