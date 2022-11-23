local View = require("lazy.view")
local Manager = require("lazy.manager")
local Util = require("lazy.core.util")

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
    Manager.clean({ clear = true, show = true })
  end,
  clear = function()
    Manager.clear()
    View.show()
  end,
  install = function()
    Manager.install({ clear = true, show = true })
  end,
  log = function()
    Manager.log({ clear = true, show = true })
  end,
  show = function()
    View.show()
  end,
  docs = function()
    Manager.docs({ clear = true, show = true })
  end,
  sync = function()
    Manager.update({ clear = true, show = true })
    Manager.install({ show = true })
    Manager.clean({ show = true })
  end,
  update = function()
    Manager.update({ clear = true, show = true })
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
