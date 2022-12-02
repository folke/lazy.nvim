local Util = require("lazy.core.util")

local M = {}

---@class LazyConfig
M.defaults = {
  defaults = {
    lazy = false, -- should plugins be loaded at startup?
    version = nil,
    -- version = "*", -- enable this to try installing the latest stable versions of plugins
  },
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- lockfile generated after running update.
  concurrency = nil, -- set to a number to limit the maximum amount of concurrent tasks
  git = {
    -- defaults for `Lazy log`
    -- log = { "-10" }, -- last 10 commits
    log = { "--since=1 days ago" }, -- commits from the last 3 days
    timeout = 120, -- processes taking over 2 minutes will be killed
  },
  package = {
    path = vim.fn.stdpath("data") .. "/site",
    name = "lazy", -- plugins will be installed under package.path/pack/{name}/opt
  },
  -- Any plugin spec that contains one of the patterns will use your
  -- local repo in the projects folder instead of fetchig it from github
  -- Mostly useful for plugin developers.
  dev = {
    path = vim.fn.expand("~/projects"), -- the path where you store your projects
    ---@type string[]
    patterns = {}, -- For example {"folke"}
  },
  install = {
    -- install missing plugins on startup. This doesn't increase startup time.
    missing = true,
    -- try to load one of the colorschemes in this list when starting an install during startup
    -- the first colorscheme that is found will be loaded
    colorscheme = { "habamax" },
  },
  ui = {
    -- The border to use for the UI window. Accepts same border values as |nvim_open_win()|.
    border = "none",
    icons = {
      start = "",
      init = " ",
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
  performance = {
    ---@type LazyCacheConfig
    cache = nil,
    reset_packpath = true, -- packpath will be reset to only include lazy. This makes packadd a lot faster
  },
  debug = false,
}

M.ns = vim.api.nvim_create_namespace("lazy")

---@type string|LazySpec Should be either a string pointing to a module, or a spec
M.spec = nil

---@type string Opt directory where plugins will be installed
M.root = nil

---@type table<string, LazyPlugin>
M.plugins = {}

---@type LazyPlugin[]
M.to_clean = {}

---@type LazyConfig
M.options = {}

---@param spec LazySpec
---@param opts? LazyConfig
function M.setup(spec, opts)
  M.spec = spec
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  M.options.performance.cache = require("lazy.core.cache")
  table.insert(M.options.install.colorscheme, "habamax")

  M.root = M.options.package.path .. "/pack/" .. M.options.package.name .. "/opt"

  if M.options.performance.reset_packpath then
    vim.go.packpath = M.options.package.path
  else
    vim.opt.packpath:prepend(M.options.package.path)
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      require("lazy.core.cache").autosave()
      require("lazy.view").setup()
      require("lazy.manage.reloader").enable()
    end,
  })

  Util.very_lazy()
end

return M
