local View = require("lazy.view")
local Manage = require("lazy.manage")
local Util = require("lazy.util")

local M = {}

---@param cmd string
function M.cmd(cmd)
  cmd = cmd == "" and "show" or cmd
  local command = M.commands[cmd]
  if command == nil then
    Util.error("Invalid lazy command '" .. cmd .. "'")
  else
    command()
  end
end

M.commands = {
  clean = function()
    Manage.clean({ clear = true, interactive = true, mode = "clean" })
  end,
  clear = function()
    Manage.clear()
    View.show()
  end,
  install = function()
    Manage.install({ clear = true, interactive = true, mode = "install" })
  end,
  log = function()
    Manage.log({ clear = true, interactive = true, mode = "log" })
  end,
  show = function()
    View.show()
  end,
  help = function()
    View.show("help")
  end,
  sync = function()
    Manage.clean({ interactive = true, clear = true, wait = true, mode = "sync" })
    Manage.update({ interactive = true })
    Manage.install({ interactive = true })
  end,
  update = function()
    Manage.update({ clear = true, interactive = true, mode = "update" })
  end,
  check = function()
    Manage.check({ clear = true, interactive = true, mode = "check" })
  end,
  restore = function()
    Manage.update({ clear = true, interactive = true, lockfile = true, mode = "restore" })
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
