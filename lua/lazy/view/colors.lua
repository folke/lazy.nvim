local M = {}

M.colors = {
  H1 = "IncSearch", -- home button
  H2 = "Bold", -- titles
  Comment = "Comment",
  Normal = "NormalFloat",
  Commit = "@variable.builtin", -- commit ref
  CommitIssue = "Number",
  CommitType = "Title", -- conventional commit type
  CommitScope = "Italic", -- conventional commit scope
  Dimmed = "Conceal", -- property
  Prop = "Conceal", -- property
  Value = "@string", -- value of a property
  NoCond = "DiagnosticWarn", -- unloaded icon for a plugin where `cond()` was false
  Local = "Constant",
  ProgressDone = "Constant", -- progress bar done
  ProgressTodo = "LineNr", -- progress bar todo
  Special = "@punctuation.special",
  ReasonRuntime = "@macro",
  ReasonPlugin = "Special",
  ReasonEvent = "Constant",
  ReasonKeys = "Statement",
  ReasonStart = "@variable.member",
  ReasonSource = "Character",
  ReasonFt = "Character",
  ReasonCmd = "Operator",
  ReasonImport = "Identifier",
  ReasonRequire = "@variable.parameter",
  Button = "CursorLine",
  ButtonActive = "Visual",
  TaskOutput = "MsgArea", -- task output
  Error = "DiagnosticError", -- task errors
  Warning = "DiagnosticWarn", -- task errors
  Info = "DiagnosticInfo", -- task errors
  Dir = "@markup.link", -- directory
  Url = "@markup.link", -- url
  Bold = { bold = true },
  Italic = { italic = true },
}

M.did_setup = false

function M.set_hl()
  for hl_group, link in pairs(M.colors) do
    local hl = type(link) == "table" and link or { link = link }
    hl.default = true
    vim.api.nvim_set_hl(0, "Lazy" .. hl_group, hl)
  end
end

function M.setup()
  if M.did_setup then
    return
  end

  M.did_setup = true

  M.set_hl()
  vim.api.nvim_create_autocmd("VimEnter", {
    callback = function()
      M.set_hl()
    end,
  })
  vim.api.nvim_create_autocmd("ColorScheme", {
    callback = function()
      M.set_hl()
    end,
  })
end

return M
