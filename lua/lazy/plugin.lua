local Config = require("lazy.core.config")
local Util = require("lazy.util")
local Module = require("lazy.core.module")
local State = require("lazy.core.state")

local M = {}

M.funcs = { run = "run", init = "init", config = "config" }

---@class LazyPlugin
---@field [1] string
---@field name string display name and name used for plugin config files
---@field pack string package name
---@field uri string
---@field modname? string
---@field modpath? string
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
---@field loaded? {[string]:string, time:number}
---@field installed? boolean
---@field run? string|fun()
---@field tasks? LazyTask[]
---@field dirty? boolean
---@field updated? {from:string, to:string}

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

function M.process_config()
  Util.lsmod(Config.paths.plugins, function(name, modpath)
    local plugin = Config.plugins[name]
    if plugin then
      local modname = Config.options.plugins .. "." .. name
      local ok, spec = pcall(Module.load, modname, modpath)
      if ok and spec then
        ---@diagnostic disable-next-line: no-unknown
        for k, v in pairs(spec) do
          if k == "requires" then
            plugin.requires = M.normalize(v)
          elseif type(v) ~= "function" or M.funcs[k] then
            ---@diagnostic disable-next-line: no-unknown
            plugin[k] = v
          end
        end
        plugin.modname = modname
        plugin.modpath = modpath
        M.plugin(plugin)
      else
        Util.error("Failed to load " .. modname .. "\n" .. spec)
      end
    end
  end)
end

function M.reload()
  Config.plugins = {}
  M.normalize(assert(Module.load(Config.options.plugins, Config.paths.main)))

  if not Config.plugins.lazy then
    M.plugin({
      "folke/lazy.nvim",
      opt = false,
    })
  end

  M.process_config()
  for _, plugin in pairs(Config.plugins) do
    if plugin.opt == nil then
      plugin.opt = Config.options.opt
    end
    plugin.dir = Config.options.package_path .. "/" .. (plugin.opt and "opt" or "start") .. "/" .. plugin.pack
    M.process_local(plugin)
  end
  State.update_state()
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
      spec.requires = M.normalize(spec.requires)
    end
    table.insert(results, spec.name)
  end
  return results
end

-- profile(M.rebuild, 1000, true)

return M
