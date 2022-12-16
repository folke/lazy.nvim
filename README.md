# 💤 lazy.nvim

**lazy.nvim** is a modern plugin manager for Neovim.

![image](https://user-images.githubusercontent.com/292349/207705153-077e183e-ae5f-4cbe-b1d8-07b7bf86026e.png)

## ✨ Features

- 📦 Manage all your Neovim plugins with a sleek and intuitive UI
- 🚀 Fast startup times thanks to automatic caching and bytecode compilation of lua modules.
- 💾 Partial clones instead of shallow clones
- 🔌 Automatic lazy-loading of lua modules and lazy-loading on events, commands, filetypes, and key mappings.
- ⏳ Automatically install missing plugins before starting up Neovim, allowing you to start using it right away.
- 💪 Async execution for improved performance
- 🛠️ No need to manually compile plugins
- 🧪 Correct sequencing of dependencies
- 📁 Configurable in multiple files
- 📚 Generates helptags of the headings in `README.md` files for plugins that don't have vimdocs
- 💻 Dev options and patterns for using local plugins
- 📊 Profiling tools to optimize performance
- 🔒 Lockfile `lazy-lock.json` to keep track of installed plugins
- 🔎 Automatically check for updates
- 📋 Commit, branch, tag, version, and full [Semver](https://devhints.io/semver) support
- 📈 Statusline component to see the number of pending updates

## 📄 Table of Contents

<!-- toc:start -->

- [⚡️ Requirements](#-requirements)
 - [📦 Installation](#-installation)
 - [🔌 Plugin Spec](#-plugin-spec)
 - [⚙️ Configuration](#-configuration)
 - [🚀 Usage](#-usage)
 - [📊 Profiler](#-profiler)
 - [🪲 Debug](#-debug)
 - [📦 Differences with Packer](#-differences-with-packer)
 - [📦 Other Neovim Plugin Managers in Lua](#-other-neovim-plugin-managers-in-lua)

<!-- toc:end -->

## ⚡️ Requirements

- Neovim >= **0.8.0**

## 📦 Installation

You can use the following Lua code to bootstrap **lazy.nvim**

<!-- bootstrap:start -->

```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
 if not vim.loop.fs_stat(lazypath) then
   vim.fn.system({
     "git",
     "clone",
     "--filter=blob:none",
     "--single-branch",
     "git@github.com:folke/lazy.nvim.git",
     lazypath,
   })
 end
 vim.opt.runtimepath:prepend(lazypath)
```

<!-- bootstrap:end -->

Next step is to add **lazy.nvim** to the top of your `init.lua`

```lua
-- You can use a lua module that contains your plugins.
-- All sub modules of the lua module will also be automatically loaded
-- This is the preferred setup so your plugin specs can be properly cached.
require("lazy").setup("config.plugins", {
  -- add any optional configuration here
})

-- Alternatively you can specify a plugin list
require("lazy").setup({
    "folke/neodev.nvim",
    "folke/which-key.nvim",
    { "folke/neoconf.nvim", cmd = "Neoconf" },
  }, {
  -- add any optional configuration here
})
```

## 🔌 Plugin Spec

| Property         | Type                          | Description                                                                                                                                                                                   |
| ---------------- | ----------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `[1]`            | `string?`                     | Short plugin url. Will be expanded using `config.git.url_format`                                                                                                                              |
| **dir**          | `string?`                     | A directory pointing to a local plugin                                                                                                                                                        |
| **url**          | `string?`                     | A custom git url where the plugin is hosted                                                                                                                                                   |
| **name**         | `string?`                     | A custom name for the plugin used for the local plugin directory and as the dispay name                                                                                                       |
| **dev**          | `boolean?`                    | When `true`, a local plugin directory will be used instead. See `config.dev`                                                                                                                  |
| **lazy**         | `boolean?`                    | When `true`, the plugin will only be loaded when needed. Lazy-loaded plugins are automatically loaded when their lua modules are `required`, or when one of the laz-loading handlers triggers |
| **enabled**      | `boolean?` or `fun():boolean` | When `false`, or if the `function` returns false, then this plugin will not be used                                                                                                           |
| **dependencies** | `LazySpec[]`                  | A list of plugin specs that should be loaded when the plugin loads. Dependencies are always lazy-loaded unless specified otherwise                                                            |
| **init**         | `fun(LazyPlugin)`             | `init` functions are always executed during startup                                                                                                                                           |
| **config**       | `fun(LazyPlugin)`             | `config` is executed when the plugin loads                                                                                                                                                    |
| **build**        | `fun(LazyPlugin)`             | `build` is executed when a plugin is installed or updated                                                                                                                                     |
| **branch**       | `string?`                     | Branch of the repository                                                                                                                                                                      |
| **tag**          | `string?`                     | Tag of the repository                                                                                                                                                                         |
| **commit**       | `string?`                     | Commit of the repository                                                                                                                                                                      |
| **version**      | `string?`                     | Version to use from the repository. Full [Semver](https://devhints.io/semver) ranges are supported                                                                                            |
| **pin**          | `boolean?`                    | When `true`, this plugin will not be included in updates                                                                                                                                      |
| **event**        | `string?` or `string[]`       | Lazy-load on event                                                                                                                                                                            |
| **cmd**          | `string?` or `string[]`       | Lazy-load on command                                                                                                                                                                          |
| **ft**           | `string?` or `string[]`       | Lazy-load on filetype                                                                                                                                                                         |
| **keys**         | `string?` or `string[]`       | Lazy-load on key mapping                                                                                                                                                                      |

<!-- spec:start -->

```lua
return {
  -- the colorscheme should be available when starting Neovim
  "folke/tokyonight.nvim",

  -- I have a separate config.mappings file where I require which-key.
  -- With lazy the plugin will be automatically loaded when it is required somewhere
  { "folke/which-key.nvim", lazy = true },

  {
    "nvim-neorg/neorg",
    -- lazy-load on filetype
    ft = "norg",
    -- custom config that will be executed when loading the plugin
    config = function()
      require("neorg").setup()
    end,
  },

  {
    "dstein64/vim-startuptime",
    -- lazy-load on a command
    cmd = "StartupTime",
  },

  {
    "hrsh7th/nvim-cmp",
    -- load cmp on InsertEnter
    event = "InsertEnter",
    -- these dependencies will only be loaded when cmp loads
    -- dependencies are always lazy-loaded unless specified otherwise
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
    },
    config = function()
      -- ...
    end,
  },

  -- you can use the VeryLazy event for things that can
  -- load later and are not important for the initial UI
  { "stevearc/dressing.nvim", event = "VeryLazy" },

  {
    "cshuaimin/ssr.nvim",
    -- init is always executed during startup, but doesn't load the plugin yet.
    -- init implies lazy loading
    init = function()
      vim.keymap.set({ "n", "x" }, "<leader>cR", function()
        -- this require will automatically load the plugin
        require("ssr").open()
      end, { desc = "Structural Replace" })
    end,
  },

  {
    "monaqa/dial.nvim",
    -- lazy-load on keys
    keys = { "<C-a>", "<C-x>" },
  },

  -- local plugins need to be explicitely configured with dir
  { dir = "~/projects/secret.nvim" },

  -- you can use a custom url to fetch a plugin
  { url = "git@github.com:folke/noice.nvim.git" },

  -- local plugins can also be configure with the dev option.
  -- This will use ~/projects/noice.nvim/ instead of fetching it from Github
  -- With the dev option, you can easily switch between the local and installed version of a plugin
  { "folke/noice.nvim", dev = true },
}
```

<!-- spec:end -->

## ⚙️ Configuration

**lazy.nvim** comes with the following defaults:

<!-- config:start -->

```lua
{
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
    -- automcatilly check for plugin updates
    enabled = false,
    concurrency = nil, ---@type number? set to 1 to check for updates very slowly
    notify = true, -- get a notification when new updates are found
    frequency = 3600, -- check for updates every hour
  },
  performance = {
    cache = {
      enabled = true,
      path = vim.fn.stdpath("state") .. "/lazy.state",
      -- Once one of the following events triggers, caching will be disabled.
      -- To cache all modules, set this to `{}`, but that is not recommended.
      -- The default is to disable on:
      --  * VimEnter: not useful to cache anything else beyond startup
      --  * BufReadPre: this will be triggered early when opening a file from the command line directly
      disable_events = { "VimEnter", "BufReadPre" },
    },
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
}
```

<!-- config:end -->

## 🚀 Usage

## 📊 Profiler

The profiling view shows you why and how long it took to load your plugins.

![image](https://user-images.githubusercontent.com/292349/207703263-3b38ca45-9779-482b-b684-4f8c3b3e76d0.png)

## 🪲 Debug

See an overview of active lazy-loading handlers and what's in the module cache

![image](https://user-images.githubusercontent.com/292349/207703522-8bb20678-bb4c-4424-80e4-add3219711c3.png)

## 📦 Differences with Packer

- **Plugin Spec**:

  - `setup` => `init`
  - `requires` => `dependencies`
  - `as` => `name`
  - `opt` => `lazy`
  - `run` => `build`
  - `lock` => `pin`
  - `module` is auto-loaded. No need to specify

## 📦 Other Neovim Plugin Managers in Lua

- [packer.nvim](https://github.com/wbthomason/packer.nvim)
- [paq-nvim](https://github.com/savq/paq-nvim)
- [neopm](https://github.com/ii14/neopm)
- [dep](https://github.com/chiyadev/dep)
- [optpack.nvim](https://github.com/notomo/optpack.nvim)
- [pact.nvim](https://github.com/rktjmp/pact.nvim)
