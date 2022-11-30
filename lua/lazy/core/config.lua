local Util = require("lazy.core.util")

local M = {}

---@class LazyConfig
M.defaults = {
  plugins = "config.plugins",
  defaults = {
    opt = false, -- should plugins default to "opt" or "start"
    version = nil,
    -- version = "*", -- enable this to try installing the latest stable versions of plugins
  },
  packpath = vim.fn.stdpath("data") .. "/site/pack/lazy", -- package path where new plugins will be installed
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- lockfile generated after running update.
  install_missing = true, -- install missing plugins on startup. This doesn't increase startup time.
  git = {
    -- defaults for `Lazy log`
    -- log = { "-10" }, -- last 10 commits
    log = { "--since=1 days ago" }, -- commits from the last 3 days
  },
  -- Any plugin spec that contains one of the patterns will use your
  -- local repo in the projects folder instead of fetchig it from github
  -- Mostly useful for plugin developers.
  dev = {
    path = vim.fn.expand("~/projects"), -- the path where you store your projects
    ---@type string[]
    patterns = {}, -- For example {"folke"}
  },
  ui = {
    -- The border to use for the UI window. Accepts same border values as |nvim_open_win()|.
    border = "none",
    icons = {
      start = "",
      plugin = " ",
      source = " ",
      config = "",
      event = "",
      keys = " ",
      cmd = " ",
      ft = " ",
      task = "✔ ",
    },
    throttle = 20, -- how frequently should the ui process render events
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
