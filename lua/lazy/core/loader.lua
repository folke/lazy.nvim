local Util = require("lazy.core.util")
local Config = require("lazy.core.config")

local M = {}

---@alias LoaderType "event"|"ft"|"module"|"keys"|"cmd"|"init"
---@type LoaderType[]
M.types = {
  "event",
  "ft",
  "module",
  "keys",
  "cmd",
}

---@type table<LoaderType, table<string, string[]>>|{init: string[]}
M.loaders = nil
---@type LazyPlugin[]
M.loading = {}

---@param plugin LazyPlugin
function M.add(plugin)
  if plugin.init or (plugin.opt == false and plugin.config) then
    table.insert(M.loaders.init, plugin.name)
  end

  for _, loader_type in ipairs(M.types) do
    local loaders = plugin[loader_type]
    if plugin[loader_type] then
      loaders = type(loaders) == "table" and loaders or { loaders }
      ---@cast loaders string[]
      for _, loader in ipairs(loaders) do
        if not M.loaders[loader_type][loader] then
          M.loaders[loader_type][loader] = {}
        end
        table.insert(M.loaders[loader_type][loader], plugin.name)
      end
    end
  end
end

function M.setup()
  if not M.loaders then
    M.loaders = { init = {} }
    for _, type in ipairs(M.types) do
      M.loaders[type] = {}
    end
    for _, plugin in pairs(Config.plugins) do
      M.add(plugin)
    end
  end

  local group = vim.api.nvim_create_augroup("lazy_loader", {
    clear = true,
  })

  -- modules
  table.insert(package.loaders, 2, M.module)

  -- events
  Util.track("loader_events")
  for event, plugins in pairs(M.loaders.event) do
    if event == "VimEnter" and vim.v.vim_did_enter == 1 then
      M.load(plugins, { event = event })
    else
      local user_event = event:match("User (.*)")
      vim.api.nvim_create_autocmd(user_event and "User" or event, {
        once = true,
        group = group,
        pattern = user_event,
        callback = function()
          Util.track("event: " .. (user_event or event))
          M.load(plugins, { event = event })
          Util.track()
        end,
      })
    end
  end
  Util.track()

  -- filetypes
  Util.track("loader_filetypes")
  for ft, plugins in pairs(M.loaders.ft) do
    vim.api.nvim_create_autocmd("FileType", {
      once = true,
      pattern = ft,
      group = group,
      callback = function()
        Util.track("filetype: " .. ft)
        M.load(plugins, { ft = ft })
        Util.track()
      end,
    })
  end
  Util.track()

  -- keys
  Util.track("loader_keys")
  for keys, plugins in pairs(M.loaders.keys or {}) do
    vim.keymap.set("n", keys, function()
      vim.keymap.del("n", keys)
      Util.track("keys: " .. keys)
      M.load(plugins, { keys = keys })
      vim.api.nvim_input(keys)
      Util.track()
    end)
  end
  Util.track()

  -- commands
  Util.track("loader_commands")
  for cmd, plugins in pairs(M.loaders.cmd or {}) do
    vim.api.nvim_create_user_command(cmd, function(event)
      vim.api.nvim_del_user_command(cmd)
      Util.track("cmd: " .. cmd)
      M.load(plugins)
      vim.cmd(
        ("%s %s%s%s %s"):format(
          event.mods or "",
          event.line1 == event.line2 and "" or event.line1 .. "," .. event.line2,
          cmd,
          event.bang and "!" or "",
          event.args
        )
      )
      Util.track()
    end, {
      bang = true,
      nargs = "*",
    })
  end
  Util.track()
end

function M.init_plugins()
  Util.track("plugin_init")
  for _, name in ipairs(M.loaders.init) do
    local plugin = Config.plugins[name]
    if plugin.init then
      Util.track(plugin.name)
      plugin.init()
      Util.track()
    end
    if plugin.opt == false then
      M.load(plugin, { package = "start" })
    end
  end
  Util.track()
end

---@param modname string
function M.module(modname)
  local idx = modname:find(".", 1, true) or #modname + 1

  while idx do
    local name = modname:sub(1, idx - 1)
    local plugins = M.loaders.module[name]
    if plugins then
      local reason = { require = modname }
      if #M.loading == 0 then
        local f = 3
        while not reason.source do
          local info = debug.getinfo(f, "S")
          f = f + 1
          if not info then
            break
          end
          if info.what ~= "C" then
            reason.source = info.source:sub(2)
          end
        end
      end
      M.load(plugins, reason)
      -- M.loaders.module[name] = nil
    end
    idx = modname:find(".", idx + 1, true)
  end

  ---@diagnostic disable-next-line: no-unknown
  local mod = package.loaded[modname]
  if type(mod) == "table" then
    return function()
      return mod
    end
  end
end

---@param plugins string|LazyPlugin|string[]|LazyPlugin[]
---@param reason {[string]:string}
function M.load(plugins, reason)
  if type(plugins) == "string" or plugins.name then
    ---@diagnostic disable-next-line: assign-type-mismatch
    plugins = { plugins }
  end

  ---@cast plugins (string|LazyPlugin)[]
  for _, plugin in ipairs(plugins) do
    if type(plugin) == "string" then
      plugin = Config.plugins[plugin]
    end

    if not plugin.loaded then
      plugin.loaded = vim.deepcopy(reason or {})
      if #M.loading > 0 then
        plugin.loaded.plugin = M.loading[#M.loading].name
      end

      table.insert(M.loading, plugin)

      Util.track(plugin.name)
      M.packadd(plugin)

      if plugin.requires then
        M.load(plugin.requires, {})
      end

      if plugin.config then
        plugin.config()
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
function M.packadd(plugin)
  if plugin.opt then
    vim.cmd.packadd(plugin.pack)
    M.source_plugin_files(plugin, true)
  else
    vim.opt.runtimepath:append(plugin.dir)
    M.source_plugin_files(plugin)
    M.source_plugin_files(plugin, true)
  end
end

---@param plugin LazyPlugin
---@param after? boolean
function M.source_plugin_files(plugin, after)
  local pattern = (after and "/after" or "") .. ("/plugin/" .. "**/*.\\(vim\\|lua\\)")

  local _, entries = pcall(vim.fn.glob, plugin.dir .. "/" .. pattern, false, true)

  if entries then
    ---@cast entries string[]
    for _, file in ipairs(entries) do
      vim.cmd("silent source " .. file)
    end
  end
end

return M
