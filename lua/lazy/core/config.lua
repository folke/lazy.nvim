local Util = require("lazy.core.util")

local M = {}

---@class LazyConfig
M.defaults = {
  plugins = "config.plugins",
  defaults = {
    opt = false, -- should plugins default to "opt" or "start"
    -- version = "*", -- enable this to try installing the latest stable versions of plugins
  },
  dev = {
    path = vim.fn.expand("~/projects"), -- the path where you store your projects
    ---@type string[]
    patterns = {}, -- For example {"folke"}
  },
  packpath = vim.fn.stdpath("data") .. "/site/pack/lazy",
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  view = {
    icons = {
      start = "",
      plugin = " ",
      source = " ",
      config = "",
      event = "",
      keys = " ",
      cmd = " ",
      ft = "",
      task = "✔ ",
    },
  },
  install_missing = true,
  git = {
    -- defaults for `Lazy log`
    log = { "-10" }, -- last 10 commits
    -- log = { "--since=3 days ago" }, -- commits from the last 3 days
  },
}

M.ns = vim.api.nvim_create_namespace("lazy")

M.paths = {
  ---@type string
  main = nil,
  ---@type string
  plugins = nil,
}

---@type table<string, LazyPlugin>
M.plugins = {}

---@type LazyPlugin[]
M.to_clean = {}

---@type LazyConfig
M.options = {}

---@param opts? LazyConfig
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  M.paths.plugins = vim.fn.stdpath("config") .. "/lua/" .. M.options.plugins:gsub("%.", "/")
  M.paths.main = M.paths.plugins .. (vim.loop.fs_stat(M.paths.plugins .. ".lua") and ".lua" or "/init.lua")

  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      require("lazy.core.module").autosave()
      require("lazy.view").setup()
    end,
  })

  Util.very_lazy()
end

return M
