local Config = require("lazy.config")
local Util = require("lazy.util")
local Loader = require("lazy.loader")
local Cache = require("lazy.cache")

local M = {}

---@class LazyPlugin
---@field [1] string
---@field name string display name and name used for plugin config files
---@field pack string package name
---@field uri string
---@field modname? string
---@field branch? string
---@field dir string
---@field opt? boolean
---@field init? fun(LazyPlugin) Will always be run
---@field config? fun(LazyPlugin) Will be executed when loading the plugin
---@field event? string|string[]
---@field cmd? string|string[]
---@field ft? string|string[]
---@field module? string|string[]
---@field keys? string|string[]
---@field requires? string[]
---@field loaded? boolean
---@field installed? boolean
---@field run? string|fun()
---@field tasks? LazyTask[]
---@field dirty? boolean

---@param plugin LazyPlugin
function M.plugin(plugin)
  local pkg = plugin[1]
  if type(pkg) ~= "string" then
    Util.error("Invalid plugin spec " .. vim.inspect(plugin))
  end

  plugin.uri = plugin.uri or ("https://github.com/" .. pkg .. ".git")
  plugin.pack = plugin.pack or plugin.name

  if not plugin.name then
    local name = plugin.uri:gsub("%.git$", ""):match("/([^/]+)$")
    plugin.pack = name
    if not name then
      name = pkg:gsub("%W+", "_")
    end
    name = name:gsub("[%.%-]n?vim$", "")
    name = name:gsub("^n?vim[%-%.]", "")
    name = name:gsub("%.lua$", "")
    name = name:gsub("%.", "_")
    plugin.name = name:lower()
  end

  if Config.plugins[plugin.name] and Config.plugins[plugin.name] ~= plugin then
    for k, v in pairs(plugin) do
      Config.plugins[plugin.name][k] = v
    end
    return Config.plugins[plugin.name]
  else
    Config.plugins[plugin.name] = plugin
  end
  return plugin
end

---@param plugin LazyPlugin
function M.process_local(plugin)
  for _, pattern in ipairs(Config.options.plugins_local.patterns) do
    if plugin[1]:find(pattern) then
      plugin.uri = Config.options.plugins_local.path .. "/" .. plugin.pack
      return
    end
  end
end

---@param plugin LazyPlugin
function M.process_config(plugin)
  local name = plugin.name
  local modname = Config.options.plugins .. "." .. name

  local spec = Cache.load(modname)
  if spec then
    -- add to loaded modules
    if spec.requires then
      spec.requires = M.normalize(spec.requires)
    end

    ---@diagnostic disable-next-line: no-unknown
    for k, v in pairs(spec) do
      ---@diagnostic disable-next-line: no-unknown
      plugin[k] = v
    end
    plugin.modname = modname
    M.plugin(plugin)
  end
end

---@param spec table
---@param results? LazyPlugin[]
function M.normalize(spec, results)
  results = results or {}
  if type(spec) == "string" then
    table.insert(results, M.plugin({ spec }).name)
  elseif #spec > 1 or vim.tbl_islist(spec) then
    ---@cast spec LazyPlugin[]
    for _, s in ipairs(spec) do
      M.normalize(s, results)
    end
  else
    ---@cast spec LazyPlugin
    spec = M.plugin(spec)

    if spec.requires then
      -- TODO: fix multiple requires in different packages
      spec.requires = M.normalize(spec.requires)
    end
    table.insert(results, spec.name)
  end
  return results
end

function M.process()
  for _, plugin in pairs(Config.plugins) do
    M.process_config(plugin)
  end

  for _, plugin in pairs(Config.plugins) do
    if plugin.opt == nil then
      plugin.opt = Config.options.opt
    end
    plugin.dir = Config.options.package_path .. "/" .. (plugin.opt and "opt" or "start") .. "/" .. plugin.pack
    plugin.installed = Util.file_exists(plugin.dir)
    M.process_local(plugin)
    Loader.add(plugin)
  end
end

return M
