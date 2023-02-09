local Util = require("lazy.core.util")
local Loader = require("lazy.core.loader")

---@class LazyCmdHandler:LazyHandler
local M = {}

function M:_load(cmd)
  vim.api.nvim_del_user_command(cmd)
  Util.track({ cmd = cmd })
  Loader.load(self.active[cmd], { cmd = cmd })
  Util.track()
end

---@param cmd string
function M:_add(cmd)
  vim.api.nvim_create_user_command(cmd, function(event)
    local command = {
      cmd = cmd,
      bang = event.bang or nil,
      mods = event.smods,
      args = event.fargs,
      count = event.count >= 0 and event.range == 0 and event.count or nil,
    }

    if event.range == 1 then
      command.range = { event.line1 }
    elseif event.range == 2 then
      command.range = { event.line1, event.line2 }
    end

    self:_load(cmd)
    vim.cmd(command)
  end, {
    bang = true,
    range = true,
    nargs = "*",
    complete = function(_, line)
      self:_load(cmd)
      -- NOTE: return the newly loaded command completion
      return vim.fn.getcompletion(line, "cmdline")
    end,
  })
end

---@param value string
function M:_del(value)
  pcall(vim.api.nvim_del_user_command, value)
end

return M
