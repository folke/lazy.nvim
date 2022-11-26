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

function M.get_loaders()
  ---@type table<LoaderType, table<string, string[]>>|{init: string[]}
  local loaders = { init = {} }
  for _, lt in ipairs(M.types) do
    loaders[lt] = {}
  end
  for _, plugin in pairs(Config.plugins) do
    if plugin.init or (plugin.opt == false) then
      table.insert(loaders.init, plugin.name)
    end
    for _, lt in ipairs(M.types) do
      if plugin[lt] then
        ---@diagnostic disable-next-line: no-unknown
        for _, loader in ipairs(type(plugin[lt]) == "table" and plugin[lt] or { plugin[lt] }) do
          loaders[lt][loader] = loaders[lt][loader] or {}
          table.insert(loaders[lt][loader], plugin.name)
        end
      end
    end
  end
  return loaders
end

function M.setup()
  M.loaders = M.loaders or M.get_loaders()

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
    local function _load(complete)
      vim.api.nvim_del_user_command(cmd)
      if complete then
        Util.track("cmd-complete: " .. cmd)
      else
        Util.track("cmd: " .. cmd)
      end
      M.load(plugins, { cmd = cmd })
      Util.track()
    end
    vim.api.nvim_create_user_command(cmd, function(event)
      _load()
      vim.cmd(
        ("%s %s%s%s %s"):format(
          event.mods or "",
          event.line1 == event.line2 and "" or event.line1 .. "," .. event.line2,
          cmd,
          event.bang and "!" or "",
          event.args or ""
        )
      )
    end, {
      bang = true,
      nargs = "*",
      complete = function()
        _load(true)
        -- HACK: trick Neovim to show the newly loaded command completion
        vim.api.nvim_input("<space><bs><tab>")
      end,
    })
  end
  Util.track()
end

function M.init_plugins()
  Util.track("plugin_init")
  for _, name in ipairs(M.loaders.init) do
    local plugin = Config.plugins[name]
    if not plugin then
      error(name)
    end
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

---@param modname string
function M.module(modname)
  local idx = modname:find(".", 1, true) or #modname + 1
  while idx do
    local name = modname:sub(1, idx - 1)
    local plugins = M.loaders.module[name]
    if plugins then
      M.loaders.module[name] = nil
      local reason = { require = modname }
      if #M.loading == 0 then
        local f = 3
        while not reason.source do
          local info = debug.getinfo(f, "S")
          if not info then
            break
          end
          if info.what ~= "C" then
            reason.source = info.source:sub(2)
          end
          f = f + 1
        end
      end
      M.load(plugins, reason)
    end
    idx = modname:find(".", idx + 1, true)
  end
end

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
