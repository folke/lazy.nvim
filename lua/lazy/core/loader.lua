local Util = require("lazy.core.util")
local Config = require("lazy.core.config")

local M = {}

---@type LazyPlugin[]
M.loading = {}

function M.setup()
  local Handler = require("lazy.core.handler")
  for t, handler in pairs(Handler.handlers) do
    Util.track(t)
    ---@type LazyPlugin[]
    local plugins = {}
    for _, plugin in pairs(Config.plugins) do
      if plugin[t] ~= nil then
        table.insert(plugins, plugin)
      end
    end
    if #plugins > 0 then
      handler(plugins)
    end
    Util.track()
  end
end

function M.init_plugins()
  Util.track("plugin_init")
  for _, plugin in pairs(Config.plugins) do
    if plugin.init then
      Util.track(plugin.name)
      Util.try(plugin.init, "Failed to run `init` for **" .. plugin.name .. "**")
      Util.track()
    end
    if plugin.opt == false then
      M.load(plugin, { start = "start" })
    end
  end
  Util.track()
end

---@class Loader
---@param plugins string|LazyPlugin|string[]|LazyPlugin[]
---@param reason {[string]:string}
---@param opts? {load_start: boolean}
function M.load(plugins, reason, opts)
  ---@diagnostic disable-next-line: cast-local-type
  plugins = type(plugins) == "string" or plugins.name and { plugins } or plugins
  ---@cast plugins (string|LazyPlugin)[]

  for _, plugin in ipairs(plugins) do
    plugin = type(plugin) == "string" and Config.plugins[plugin] or plugin
    ---@cast plugin LazyPlugin

    if not plugin.loaded then
      ---@diagnostic disable-next-line: assign-type-mismatch
      plugin.loaded = {}
      for k, v in pairs(reason) do
        plugin.loaded[k] = v
      end
      if #M.loading > 0 then
        plugin.loaded.plugin = M.loading[#M.loading].name
      end

      table.insert(M.loading, plugin)

      Util.track(plugin.name)
      M.packadd(plugin, opts and opts.load_start)

      if plugin.requires then
        M.load(plugin.requires, {})
      end

      if plugin.config then
        Util.try(plugin.config, "Failed to run `config` for " .. plugin.name)
      end

      plugin.loaded.time = Util.track().time
      table.remove(M.loading)
      vim.schedule(function()
        vim.cmd("do User LazyRender")
      end)
    end
  end
end

---@param plugin LazyPlugin
function M.packadd(plugin, load_start)
  if plugin.opt then
    vim.cmd.packadd(plugin.name)
    M.source_plugin_files(plugin, true)
  elseif load_start then
    vim.opt.runtimepath:append(plugin.dir)
    M.source_plugin_files(plugin)
    M.source_plugin_files(plugin, true)
  end
end

---@param plugin LazyPlugin
---@param after? boolean
function M.source_plugin_files(plugin, after)
  Util.walk(plugin.dir .. (after and "/after" or "") .. "/plugin", function(path, _, t)
    local ext = path:sub(-3)
    if t == "file" and (ext == "lua" or ext == "vim") then
      vim.cmd("silent source " .. path)
    end
  end)
end

return M
