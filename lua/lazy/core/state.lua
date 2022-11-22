local Cache = require("lazy.core.cache")
local Module = require("lazy.core.module")

local M = {}

M.functions = { "init", "config", "run" }
M.changed = true

function M.save()
  local Config = require("lazy.core.config")

  ---@class LazyState
  local state = {
    ---@type LazyPlugin[]
    plugins = {},
    loaders = require("lazy.core.loader").loaders,
    config = Config.options,
  }

  local skip = { installed = true, loaded = true, tasks = true, dirty = true, [1] = true, dir = true }
  local funcount = 0

  for _, plugin in pairs(Config.plugins) do
    ---@type LazyPlugin | {_chunks: string[] | table<string, number>}
    local save = {}
    table.insert(state.plugins, save)
    for k, v in pairs(plugin) do
      if type(v) == "function" then
        if vim.tbl_contains(M.functions, k) then
          if plugin.modname then
            save[k] = true
          else
            funcount = funcount + 1
            Cache.set("cache.state.fun." .. funcount, string.dump(v))
            save[k] = funcount
          end
        end
      elseif not skip[k] then
        save[k] = v
      end
    end
  end
  Cache.set("cache.state", vim.json.encode(state))
end

local function load_plugin(plugin, fun, ...)
  local mod = Module.load(plugin.modname)
  for k, v in pairs(mod) do
    if type(v) == "function" then
      plugin[k] = v
    end
  end
  return mod[fun](...)
end

function M.load()
  ---@type boolean, LazyState
  local ok, state = pcall(vim.json.decode, Cache.get("cache.state"))
  if not ok then
    Cache.dirty()
    return false
  end

  local Util = require("lazy.core.util")
  local Config = require("lazy.core.config")

  if not vim.deep_equal(Config.options, state.config) then
    Cache.dirty()
    return false
  end

  -- Check for installed plugins
  ---@type table<"opt"|"start", table<string,boolean>>
  local installed = { opt = {}, start = {} }
  for _, opt in ipairs({ "opt", "start" }) do
    for _, entry in ipairs(Util.scandir(Config.options.package_path .. "/" .. opt)) do
      if entry.type == "directory" or entry.type == "link" then
        installed[opt][entry.name] = true
      end
    end
  end

  -- plugins
  for _, plugin in ipairs(state.plugins) do
    ---@cast plugin LazyPlugin|{_chunks:table}
    Config.plugins[plugin.name] = plugin
    plugin.loaded = false
    plugin.dir = Config.options.package_path .. "/" .. (plugin.opt and "opt" or "start") .. "/" .. plugin.pack
    plugin.installed = installed[plugin.opt and "opt" or "start"][plugin.pack]
    if plugin.modname then
      -- mark module as used
      assert(Cache.get(plugin.modname))
      for _, fun in ipairs(M.functions) do
        if plugin[fun] == true then
          plugin[fun] = function(...)
            return load_plugin(plugin, fun, ...)
          end
        end
      end
    else
      for _, fun in ipairs(M.functions) do
        if type(plugin[fun]) == "number" then
          local chunk = assert(Cache.get("cache.state.fun." .. plugin[fun]))
          plugin[fun] = function(...)
            plugin[fun] = loadstring(chunk)
            return plugin[fun](...)
          end
        end
      end
    end
  end

  -- loaders
  local Loader = require("lazy.core.loader")
  Loader.loaders = state.loaders

  M.changed = false

  return true
end

return M
