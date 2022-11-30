local View = require("lazy.view")
local Manage = require("lazy.manage")
local Util = require("lazy.util")

local M = {}

---@param cmd string
---@param plugins? LazyPlugin[]
function M.cmd(cmd, plugins)
  cmd = cmd == "" and "show" or cmd
  local command = M.commands[cmd]
  if command == nil then
    Util.error("Invalid lazy command '" .. cmd .. "'")
  else
    command(plugins)
  end
end

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
  show = function()
    View.show()
  end,
  help = function()
    View.show("help")
  end,
  profile = function()
    View.show("profile")
  end,
  sync = function()
    Manage.clean({ clear = true, wait = true, mode = "sync" })
    Manage.update({ interactive = true })
    Manage.install({ interactive = true })
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
}

function M.setup()
  vim.api.nvim_create_user_command("Lazy", function(args)
    M.cmd(vim.trim(args.args or ""))
  end, {
    nargs = "?",
    desc = "Lazy",
    complete = function(_, line)
      if line:match("^%s*Lazy %w+ ") then
        return {}
      end

      local prefix = line:match("^%s*Lazy (%w*)") or ""

      ---@param key string
      return vim.tbl_filter(function(key)
        return key:find(prefix) == 1
      end, vim.tbl_keys(M.commands))
    end,
  })

  for name in pairs(M.commands) do
    local cmd = "Lazy" .. name:sub(1, 1):upper() .. name:sub(2)

    vim.api.nvim_create_user_command(cmd, function()
      M.cmd(name)
    end, {
      desc = "Lazy " .. name,
    })
  end
end

return M
