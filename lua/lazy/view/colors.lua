local M = {}

M.colors = {
  Error = "ErrorMsg",
  H1 = "Title",
  H2 = "Bold",
  Muted = "Comment",
  Normal = "NormalFloat",
  Commit = "@variable.builtin",
  Key = "Conceal",
  Value = "@string",
  ProgressDone = {
    bold = true,
    default = true,
    fg = "#ff007c",
  },
  ProgressTodo = "LineNr",
  Special = "@punctuation.special",
  LoaderPlugin = "Special",
  LoaderEvent = "Constant",
  LoaderKeys = "Statement",
  LoaderStart = "@field",
  LoaderSource = "Character",
  LoaderCmd = "Operator"
}

M.did_setup = false

function M.set_hl()
  for hl_group, opts in pairs(M.colors) do
    if type(opts) == "string" then
      opts = { link = opts }
    end
    opts.default = true
    vim.api.nvim_set_hl(0, "Lazy" .. hl_group, opts)
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
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    callback = function()
      M.set_hl()
    end,
  })
end

return M
