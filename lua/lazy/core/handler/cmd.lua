local Loader = require("lazy.core.loader")
local Util = require("lazy.core.util")

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

    ---@type string
    local plugins = "`" .. table.concat(vim.tbl_values(self.active[cmd]), ", ") .. "`"

    self:_load(cmd)

    local info = vim.api.nvim_get_commands({})[cmd] or vim.api.nvim_buf_get_commands(0, {})[cmd]
    if not info then
      vim.schedule(function()
        Util.error("Command `" .. cmd .. "` not found after loading " .. plugins)
      end)
      return
    end

    command.nargs = info.nargs
    if event.args and event.args ~= "" and info.nargs and info.nargs:find("[1?]") then
      command.args = { event.args }
    end
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
