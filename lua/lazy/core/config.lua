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
  concurrency = nil, ---@type number limit the maximum amount of concurrent tasks
  git = {
    -- defaults for the `Lazy log` command
    -- log = { "-10" }, -- show the last 10 commits
    log = { "--since=1 days ago" }, -- show commits from the last 3 days
    timeout = 120, -- kill processes that take more than 2 minutes
    url_format = "https://github.com/%s.git",
  },
  dev = {
    -- directory where you store your local plugin projects
    path = vim.fn.expand("~/projects"),
    ---@type string[] plugins that match these patterns will use your local versions instead of being fetched from GitHub
    patterns = {}, -- For example {"folke"}
  },
  install = {
    -- install missing plugins on startup. This doesn't increase startup time.
    missing = true,
    -- try to load one of these colorschemes when starting an installation during startup
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
    -- automatically check for plugin updates
    enabled = false,
    concurrency = nil, ---@type number? set to 1 to check for updates very slowly
    notify = true, -- get a notification when new updates are found
    frequency = 3600, -- check for updates every hour
  },
  performance = {
    ---@type LazyCacheConfig
    cache = nil,
    reset_packpath = true, -- reset the package path to improve startup time
    rtp = {
      reset = true, -- reset the runtime path to $VIMRUNTIME and your config directory
      ---@type string[] list any plugins you want to disable here
      disabled_plugins = {
        -- "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        -- "tarPlugin",
        -- "tohtml",
        -- "tutor",
        -- "zipPlugin",
      },
    },
  },
  -- lazy can generate helptags from the headings in markdown readme files,
  -- so :help works even for plugins that don't have vim docs.
  -- when the readme opens with :help it will be correctly displayed as markdown
  readme = {
    root = vim.fn.stdpath("state") .. "/lazy/readme",
    files = { "README.md" },
    -- only generate markdown helptags for plugins that dont have docs
    skip_if_doc_exists = true,
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

---@type string
M.me = nil

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
  if M.options.performance.rtp.reset then
    M.me = debug.getinfo(1, "S").source:sub(2)
    M.me = vim.fn.fnamemodify(M.me, ":p:h:h:h:h")
    vim.opt.rtp = {
      M.me,
      vim.env.VIMRUNTIME,
      vim.fn.stdpath("config"),
      vim.fn.stdpath("config") .. "/after",
    }
  end
  vim.opt.rtp:append(M.options.readme.root)

  -- disable plugin loading since we do all of that ourselves
  vim.go.loadplugins = false

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
