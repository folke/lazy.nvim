local M = {}

M.colors = {
  Error = "ErrorMsg", -- task errors
  H1 = "IncSearch",
  H2 = "Bold",
  Muted = "Comment",
  Normal = "NormalFloat",
  Commit = "@variable.builtin",
  Key = "Conceal",
  Value = "@string",
  NoCond = "DiagnosticError",
  ProgressDone = "Constant", -- progress bar done
  ProgressTodo = "LineNr", -- progress bar todo
  Special = "@punctuation.special",
  HandlerRuntime = "@macro",
  HandlerPlugin = "Special",
  HandlerEvent = "Constant",
  HandlerKeys = "Statement",
  HandlerStart = "@field",
  HandlerSource = "Character",
  HandlerFt = "Character",
  HandlerCmd = "Operator",
  Button = "CursorLine",
  ButtonActive = "Visual",
}

M.did_setup = false

function M.set_hl()
  for hl_group, link in pairs(M.colors) do
    vim.api.nvim_set_hl(0, "Lazy" .. hl_group, {
      link = link,
      default = true,
    })
  end
end

function M.setup()
  if M.did_setup then
    return
  end

  M.did_setup = true

  M.set_hl()
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      M.set_hl()
    end,
  })
end

return M
