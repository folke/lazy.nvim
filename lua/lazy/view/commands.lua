local View = require("lazy.view")
local Manage = require("lazy.manage")
local Util = require("lazy.util")
local Config = require("lazy.core.config")

local M = {}

---@param cmd string
---@param plugins? LazyPlugin[]
function M.cmd(cmd, plugins)
  cmd = cmd == "" and "home" or cmd
  local command = M.commands[cmd]
  if command == nil then
    Util.error("Invalid lazy command '" .. cmd .. "'")
  else
    command(plugins)
  end
end

---@class LazyCommands
M.commands = {
  clean = function(plugins)
    Manage.clean({ clear = true, mode = "clean", plugins = plugins })
  end,
  clear = function()
    Manage.clear()
    View.show()
  end,
  install = function()
    Manage.install({ clear = true, mode = "install" })
  end,
  log = function(plugins)
    Manage.log({ clear = true, mode = "log", plugins = plugins })
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
  sync = function()
    Manage.clean({ clear = true, wait = true, mode = "sync" })
    Manage.update()
    Manage.install()
  end,
  update = function(plugins)
    Manage.update({ clear = true, mode = "update", plugins = plugins })
  end,
  check = function(plugins)
    Manage.check({ clear = true, mode = "check", plugins = plugins })
  end,
  restore = function(plugins)
    Manage.update({ clear = true, lockfile = true, mode = "restore", plugins = plugins })
  end,
  load = function(plugins)
    require("lazy.core.loader").load(plugins, { cmd = "LazyLoad" })
  end,
}

function M.complete_unloaded(prefix)
  local plugins = {}
  for name, plugin in pairs(Config.plugins) do
    if not plugin._.loaded then
      plugins[#plugins + 1] = name
    end
  end
  table.sort(plugins)
  ---@param key string
  return vim.tbl_filter(function(key)
    return key:find(prefix) == 1
  end, plugins)
end

function M.setup()
  vim.api.nvim_create_user_command("Lazy", function(cmd)
    local args = vim.split(vim.trim(cmd.args or ""), " ")
    local name = args[1]
    table.remove(args, 1)
    M.cmd(name, #args > 0 and args or nil)
  end, {
    nargs = "?",
    desc = "Lazy",
    complete = function(_, line)
      ---@type string?
      local prefix = line:match("^%s*Lazy load (%w*)")
      if prefix then
        return M.complete_unloaded(prefix)
      end

      if line:match("^%s*Lazy %w+ ") then
        return {}
      end

      prefix = line:match("^%s*Lazy (%w*)") or ""

      ---@param key string
      return vim.tbl_filter(function(key)
        return key:find(prefix) == 1
      end, vim.tbl_keys(M.commands))
    end,
  })
end

return M
