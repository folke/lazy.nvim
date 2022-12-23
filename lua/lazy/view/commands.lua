local View = require("lazy.view")
local Manage = require("lazy.manage")
local Util = require("lazy.util")
local Config = require("lazy.core.config")
local ViewConfig = require("lazy.view.config")

local M = {}

---@param cmd string
---@param opts? ManagerOpts
function M.cmd(cmd, opts)
  cmd = cmd == "" and "home" or cmd
  local command = M.commands[cmd] --[[@as fun(opts)]]
  if command == nil then
    Util.error("Invalid lazy command '" .. cmd .. "'")
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
    if not (opts and opts.plugins and #opts.plugins > 0) then
      return Util.error("`Lazy load` requires at least one plugin name to load")
    end
    require("lazy.core.loader").load(opts.plugins, { cmd = "LazyLoad" })
  end,
  log = Manage.log,
  clean = Manage.clean,
  install = Manage.install,
  sync = Manage.sync,
  update = Manage.update,
  check = Manage.check,
  restore = Manage.restore,
}

function M.complete(cmd, prefix)
  if not ViewConfig.commands[cmd].plugins then
    return
  end
  ---@type string[]
  local plugins = {}
  for name, plugin in pairs(Config.plugins) do
    if cmd ~= "load" or not plugin._.loaded then
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
    ---@type ManagerOpts
    local opts = { wait = cmd.bang == true }
    local prefix, args = M.parse(cmd.args)
    if #args > 0 then
      ---@param plugin string
      opts.plugins = vim.tbl_map(function(plugin)
        return Config.plugins[plugin]
      end, args)
    end
    M.cmd(prefix, opts)
  end, {
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
        return key:find(prefix) == 1
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
