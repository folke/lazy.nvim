local Util = require("lazy.core.util")

local M = {}

---@class LazyConfig
M.defaults = {
  root = vim.fn.stdpath("data") .. "/lazy", -- directory where plugins will be installed
  defaults = {
    lazy = false, -- should plugins be lazy-loaded?
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
    url_format = "https://github.com/%s.git",
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
      cmd = " ",
      config = "",
      event = "",
      ft = " ",
      init = " ",
      keys = " ",
      plugin = " ",
      runtime = " ",
      source = " ",
      start = "",
      task = "✔ ",
    },
    throttle = 20, -- how frequently should the ui process render events
  },
  checker = {
    -- lazy can automatically check for updates
    enabled = false,
    concurrency = nil, ---@type number? set to 1 to very slowly check for updates
    notify = true, -- get a notification if new updates are found
    frequency = 3600, -- every hour
  },
  performance = {
    ---@type LazyCacheConfig
    cache = nil,
    reset_packpath = true, -- packpath will be reset to nothing. This will improver startup time.
    reset_rtp = true, -- the runtime path will be reset to $VIMRUNTIME and your config directory
  },
  debug = false,
}

M.ns = vim.api.nvim_create_namespace("lazy")

---@type string|LazySpec Should be either a string pointing to a module, or a spec
M.spec = nil

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

  if M.options.performance.reset_packpath then
    vim.go.packpath = ""
  end
  if M.options.performance.reset_rtp then
    local me = debug.getinfo(1, "S").source:sub(2)
    me = vim.fn.fnamemodify(me, ":p:h:h:h:h")
    vim.opt.rtp = {
      "$VIMRUNTIME",
      vim.fn.stdpath("config"),
      me,
      vim.fn.stdpath("config") .. "/after",
    }
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      require("lazy.core.cache").autosave()
      require("lazy.view").setup()
      require("lazy.manage.reloader").enable()
      if M.options.checker.enabled then
        require("lazy.manage.checker").start()
      end
    end,
  })

  Util.very_lazy()
end

return M
