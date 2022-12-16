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
    self:_load(cmd)
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
    complete = function(_, line)
      self:_load(cmd)
      -- NOTE: return the newly loaded command completion
      return vim.fn.getcompletion(line, "cmdline")
    end,
  })
end

---@param _plugin LazyPlugin
---@param value string
function M:_del(_plugin, value)
  pcall(vim.api.nvim_del_user_command, value)
end

return M
