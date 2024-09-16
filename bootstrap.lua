-- Lazy Bootstrapper
-- Usage:
-- ```lua
-- load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()
-- ```
local M = {}

function M.setup()
  if vim.env.LAZY_STDPATH then
    local root = vim.fn.fnamemodify(vim.env.LAZY_STDPATH, ":p"):gsub("[\\/]$", "")
    for _, name in ipairs({ "config", "data", "state", "cache" }) do
      vim.env[("XDG_%s_HOME"):format(name:upper())] = root .. "/" .. name
    end
  end

  if vim.env.LAZY_PATH and not vim.uv.fs_stat(vim.env.LAZY_PATH) then
    vim.env.LAZY_PATH = nil
  end

  local lazypath = vim.env.LAZY_PATH or vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.env.LAZY_PATH and not (vim.uv or vim.loop).fs_stat(lazypath) then
    vim.api.nvim_echo({
      {
        "Cloning lazy.nvim\n\n",
        "DiagnosticInfo",
      },
    }, true, {})
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local ok, out = pcall(vim.fn.system, {
      "git",
      "clone",
      "--filter=blob:none",
      lazyrepo,
      lazypath,
    })
    if not ok or vim.v.shell_error ~= 0 then
      vim.api.nvim_echo({
        { "Failed to clone lazy.nvim\n", "ErrorMsg" },
        { vim.trim(out or ""), "WarningMsg" },
        { "\nPress any key to exit...", "MoreMsg" },
      }, true, {})
      vim.fn.getchar()
      os.exit(1)
    end
  end
  vim.opt.rtp:prepend(lazypath)
end
M.setup()

return M
