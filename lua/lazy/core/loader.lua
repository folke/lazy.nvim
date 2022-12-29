local Util = require("lazy.core.util")
local Config = require("lazy.core.config")
local Handler = require("lazy.core.handler")

local M = {}

local DEFAULT_PRIORITY = 50

---@type LazyPlugin[]
M.loading = {}
M.init_done = false
---@type table<string,true>
M.disabled_rtp_plugins = { packer_compiled = true }

function M.setup()
  -- setup handlers
  Util.track("handlers")
  Handler.setup()
  Util.track()

  for _, file in ipairs(Config.options.performance.rtp.disabled_plugins) do
    M.disabled_rtp_plugins[file] = true
  end

  vim.api.nvim_create_autocmd("ColorSchemePre", {
    callback = function(event)
      M.colorscheme(event.match)
    end,
  })

  -- install missing plugins
  if Config.options.install.missing then
    Util.track("install")
    for _, plugin in pairs(Config.plugins) do
      if not plugin._.installed then
        for _, colorscheme in ipairs(Config.options.install.colorscheme) do
          if pcall(vim.cmd.colorscheme, colorscheme) then
            break
          end
        end
        require("lazy.manage").install({ wait = true })
        break
      end
    end
    Util.track()
  end
end

-- Startup sequence
-- 1. load any start plugins and do init
function M.startup()
  Util.track({ start = "startup" })

  -- load filetype.lua first since plugins might depend on that
  M.source(vim.env.VIMRUNTIME .. "/filetype.lua")

  -- backup original rtp
  local rtp = vim.opt.rtp:get()

  -- 1. run plugin init
  Util.track({ start = "init" })
  for _, plugin in pairs(Config.plugins) do
    if plugin.init then
      Util.track({ plugin = plugin.name, init = "init" })
      Util.try(function()
        plugin.init(plugin)
      end, "Failed to run `init` for **" .. plugin.name .. "**")
      Util.track()
    end
  end
  Util.track()

  -- 2. load start plugin
  Util.track({ start = "start" })
  for _, plugin in ipairs(M.get_start_plugins()) do
    -- plugin may be loaded by another plugin in the meantime
    if not plugin._.loaded then
      M.load(plugin, { start = "start" })
    end
  end
  Util.track()

  -- 3. load plugins from rtp, excluding after
  Util.track({ start = "rtp plugins" })
  for _, path in ipairs(rtp) do
    if not path:find("after/?$") then
      M.packadd(path)
    end
  end
  Util.track()

  -- 4. load after plugins
  Util.track({ start = "after" })
  for _, path in ipairs(vim.opt.rtp:get()) do
    if path:find("after/?$") then
      M.source_runtime(path, "plugin")
    end
  end
  Util.track()

  M.init_done = true

  Util.track()
end

function M.get_start_plugins()
  ---@type LazyPlugin[]
  local start = {}
  for _, plugin in pairs(Config.plugins) do
    if plugin.lazy == false and not plugin._.loaded then
      start[#start + 1] = plugin
    end
  end
  table.sort(start, function(a, b)
    local ap = a.priority or DEFAULT_PRIORITY
    local bp = b.priority or DEFAULT_PRIORITY
    return ap > bp
  end)
  return start
end

---@class Loader
---@param plugins string|LazyPlugin|string[]|LazyPlugin[]
---@param reason {[string]:string}
function M.load(plugins, reason)
  ---@diagnostic disable-next-line: cast-local-type
  plugins = (type(plugins) == "string" or plugins.name) and { plugins } or plugins
  ---@cast plugins (string|LazyPlugin)[]

  for _, plugin in pairs(plugins) do
    if type(plugin) == "string" then
      if Config.plugins[plugin] then
        plugin = Config.plugins[plugin]
      else
        Util.error("Plugin " .. plugin .. " not found")
        plugin = nil
      end
    end
    if plugin and not plugin._.loaded then
      M._load(plugin, reason)
    end
  end
end

---@param plugin LazyPlugin
---@param reason {[string]:string}
function M._load(plugin, reason)
  if not plugin._.installed then
    return Util.error("Plugin " .. plugin.name .. " is not installed")
  end

  if plugin.cond ~= nil then
    if plugin.cond == false or (type(plugin.cond) == "function" and not plugin.cond()) then
      plugin._.cond = false
      return
    end
  end

  ---@diagnostic disable-next-line: assign-type-mismatch
  plugin._.loaded = {}
  for k, v in pairs(reason) do
    plugin._.loaded[k] = v
  end
  if #M.loading > 0 then
    plugin._.loaded.plugin = M.loading[#M.loading].name
  elseif reason.require then
    plugin._.loaded.source = Util.get_source()
  end

  table.insert(M.loading, plugin)

  Util.track({ plugin = plugin.name, start = reason.start })
  Handler.disable(plugin)

  vim.opt.runtimepath:prepend(plugin.dir)
  local after = plugin.dir .. "/after"
  if vim.loop.fs_stat(after) then
    vim.opt.runtimepath:append(after)
  end

  if plugin.dependencies then
    Util.try(function()
      M.load(plugin.dependencies, {})
    end, "Failed to load deps for " .. plugin.name)
  end

  M.packadd(plugin.dir)
  if plugin.config then
    M.config(plugin)
  end

  plugin._.loaded.time = Util.track().time
  table.remove(M.loading)
  vim.schedule(function()
    vim.cmd("do User LazyRender")
  end)
end

--- runs plugin config
---@param plugin LazyPlugin
function M.config(plugin)
  local fn
  if type(plugin.config) == "function" then
    fn = function()
      plugin.config(plugin)
    end
  else
    local normname = Util.normname(plugin.name)
    ---@type table<string, string>
    local mods = {}
    Util.ls(plugin.dir .. "/lua", function(_, modname)
      modname = modname:gsub("%.lua$", "")
      mods[modname] = modname
      local modnorm = Util.normname(modname)
      -- if we found an exact match, then use that
      if modnorm == normname then
        mods = { modname }
        return false
      end
    end)
    mods = vim.tbl_values(mods)
    if #mods == 1 then
      fn = function()
        local opts = plugin.config
        if opts == true then
          opts = nil
        end
        require(mods[1]).setup(opts)
      end
    else
      return Util.error(
        "Lua module not found for config of " .. plugin.name .. ". Please use a `config()` function instead"
      )
    end
  end
  Util.try(fn, "Failed to run `config` for " .. plugin.name)
end

---@param path string
function M.packadd(path)
  M.source_runtime(path, "plugin")
  M.ftdetect(path)
  if M.init_done then
    M.source_runtime(path, "after/plugin")
  end
end

---@param path string
function M.ftdetect(path)
  vim.cmd("augroup filetypedetect")
  M.source_runtime(path, "ftdetect")
  vim.cmd("augroup END")
end

---@param ... string
function M.source_runtime(...)
  local dir = table.concat({ ... }, "/")
  ---@type string[]
  local files = {}
  Util.walk(dir, function(path, name, t)
    local ext = name:sub(-3)
    name = name:sub(1, -5)
    if (t == "file" or t == "link") and (ext == "lua" or ext == "vim") and not M.disabled_rtp_plugins[name] then
      files[#files + 1] = path
    end
  end)
  -- plugin files are sourced alphabetically per directory
  table.sort(files)
  for _, path in ipairs(files) do
    M.source(path)
  end
end

function M.source(path)
  Util.track({ runtime = path })
  Util.try(function()
    vim.cmd("silent source " .. path)
  end, "Failed to source `" .. path .. "`")
  Util.track()
end

function M.colorscheme(name)
  if vim.tbl_contains(vim.fn.getcompletion("", "color"), name) then
    return
  end
  for _, plugin in pairs(Config.plugins) do
    if not plugin._.loaded then
      for _, ext in ipairs({ "lua", "vim" }) do
        local path = plugin.dir .. "/colors/" .. name .. "." .. ext
        if vim.loop.fs_stat(path) then
          return M.load(plugin, { colorscheme = name })
        end
      end
    end
  end
end

return M
