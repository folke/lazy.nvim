local require = require("lazy.core.util").lazy_require
local Config = require("lazy.core.config")
local Manage = require("lazy.manage")
local Util = require("lazy.util")
local View = require("lazy.view")
local ViewConfig = require("lazy.view.config")

local M = {}

---@param cmd string
---@param opts? ManagerOpts
function M.cmd(cmd, opts)
  cmd = cmd == "" and "home" or cmd
  local command = M.commands[cmd] --[[@as fun(opts)]]
  if command == nil then
    Util.error("Invalid lazy command '" .. cmd .. "'")
  elseif
    ViewConfig.commands[cmd]
    and ViewConfig.commands[cmd].plugins_required
    and not (opts and vim.tbl_count(opts.plugins or {}) > 0)
  then
    return Util.error("`Lazy " .. cmd .. "` requires at least one plugin")
  else
    command(opts)
  end
end

---@class LazyCommands
M.commands = {
  clear = function()
    Manage.clear()
    View.show()
  end,
  health = function()
    vim.cmd.checkhealth("lazy")
  end,
  home = function()
    View.show("home")
  end,
  show = function()
    View.show("home")
  end,
  help = function()
    View.show("help")
  end,
  debug = function()
    View.show("debug")
  end,
  profile = function()
    View.show("profile")
  end,
  ---@param opts ManagerOpts
  load = function(opts)
    -- when a command is executed with a bang, wait will be set
    require("lazy.core.loader").load(opts.plugins, { cmd = "Lazy load" }, { force = opts.wait })
  end,
  reload = function(opts)
    for _, plugin in pairs(opts.plugins) do
      Util.warn("Reloading **" .. plugin.name .. "**")
      require("lazy.core.loader").reload(plugin)
    end
  end,
  log = Manage.log,
  build = Manage.build,
  clean = Manage.clean,
  install = Manage.install,
  sync = Manage.sync,
  update = Manage.update,
  check = Manage.check,
  restore = Manage.restore,
}

function M.complete(cmd, prefix)
  if not (ViewConfig.commands[cmd] or {}).plugins then
    return
  end
  ---@type string[]
  local plugins = {}
  if cmd == "load" then
    plugins[#plugins + 1] = "all"
  end
  for name, plugin in pairs(Config.plugins) do
    if cmd ~= "load" or not plugin._.loaded then
      plugins[#plugins + 1] = name
    end
  end
  table.sort(plugins)
  ---@param key string
  return vim.tbl_filter(function(key)
    return key:find(prefix, 1, true) == 1
  end, plugins)
end

function M.setup()
  vim.api.nvim_create_user_command("Lazy", function(cmd)
    ---@type ManagerOpts
    local opts = { wait = cmd.bang == true }
    local prefix, args = M.parse(cmd.args)
    if #args == 1 and args[1] == "all" then
      args = vim.tbl_keys(Config.plugins)
    end
    if #args > 0 then
      ---@param plugin string
      opts.plugins = vim.tbl_map(function(plugin)
        return Config.plugins[plugin]
      end, args)
    end
    M.cmd(prefix, opts)
  end, {
    bar = true,
    bang = true,
    nargs = "?",
    desc = "Lazy",
    complete = function(_, line)
      local prefix, args = M.parse(line)
      if #args > 0 then
        return M.complete(prefix, args[#args])
      end

      ---@param key string
      return vim.tbl_filter(function(key)
        return key:find(prefix, 1, true) == 1
      end, vim.tbl_keys(M.commands))
    end,
  })
end

---@return string, string[]
function M.parse(args)
  local parts = vim.split(vim.trim(args), "%s+")
  if parts[1]:find("Lazy") then
    table.remove(parts, 1)
  end
  if args:sub(-1) == " " then
    parts[#parts + 1] = ""
  end
  return table.remove(parts, 1) or "", parts
end

return M
