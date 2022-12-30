# 💤 lazy.nvim

**lazy.nvim** is a modern plugin manager for Neovim.

![image](https://user-images.githubusercontent.com/292349/208301737-68fb279c-ba70-43ef-a369-8c3e8367d6b1.png)

## ✨ Features

- 📦 Manage all your Neovim plugins with a powerful UI
- 🚀 Fast startup times thanks to automatic caching and bytecode compilation of lua modules
- 💾 Partial clones instead of shallow clones
- 🔌 Automatic lazy-loading of lua modules and lazy-loading on events, commands, filetypes, and key mappings
- ⏳ Automatically install missing plugins before starting up Neovim, allowing you to start using it right away
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
- 🎨 Automatically lazy-loads colorschemes

## ⚡️ Requirements

- Neovim >= **0.8.0** (needs to be built with **LuaJIT**)
- Git >= **2.19.0** (for partial clones support)
- a [Nerd Font](https://www.nerdfonts.com/) **_(optional)_**

## 📦 Installation

You can add the following Lua code to your `init.lua` to bootstrap **lazy.nvim**

<!-- bootstrap:start -->

```lua
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable", -- remove this if you want to bootstrap to HEAD
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
```

<!-- bootstrap:end -->

Next step is to add **lazy.nvim** to the top of your `init.lua`

```lua
require("lazy").setup(plugins, opts)
```

- **plugins**: this should be a `table` or a `string`
  - `table`: a list with your [Plugin Spec](#-plugin-spec)
  - `string`: a Lua module name that contains your [Plugin Spec](#-plugin-spec). See [Structuring Your Plugins](#-structuring-your-plugins)
- **opts**: see [Configuration](#%EF%B8%8F-configuration) **_(optional)_**

```lua
-- example using a list of specs with the default options
vim.g.mapleader = " " -- make sure to set `mapleader` before lazy so your mappings are correct

require("lazy").setup({
  "folke/which-key.nvim",
  { "folke/neoconf.nvim", cmd = "Neoconf" },
  "folke/neodev.nvim",
})
```

ℹ️ It is recommended to run `:checkhealth lazy` after installation

## 🔌 Plugin Spec

| Property         | Type                                                      | Description                                                                                                                                                                                                                            |
| ---------------- | --------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `[1]`            | `string?`                                                 | Short plugin url. Will be expanded using `config.git.url_format`                                                                                                                                                                       |
| **dir**          | `string?`                                                 | A directory pointing to a local plugin                                                                                                                                                                                                 |
| **url**          | `string?`                                                 | A custom git url where the plugin is hosted                                                                                                                                                                                            |
| **name**         | `string?`                                                 | A custom name for the plugin used for the local plugin directory and as the display name                                                                                                                                               |
| **dev**          | `boolean?`                                                | When `true`, a local plugin directory will be used instead. See `config.dev`                                                                                                                                                           |
| **lazy**         | `boolean?`                                                | When `true`, the plugin will only be loaded when needed. Lazy-loaded plugins are automatically loaded when their Lua modules are `required`, or when one of the lazy-loading handlers triggers                                         |
| **enabled**      | `boolean?` or `fun():boolean`                             | When `false`, or if the `function` returns false, then this plugin will not be included in the spec                                                                                                                                    |
| **cond**         | `boolean?` or `fun():boolean`                             | When `false`, or if the `function` returns false, then this plugin will not be loaded. Useful to disable some plugins in vscode, or firenvim for example.                                                                              |
| **dependencies** | `LazySpec[]`                                              | A list of plugin names or plugin specs that should be loaded when the plugin loads. Dependencies are always lazy-loaded unless specified otherwise. When specifying a name, make sure the plugin spec has been defined somewhere else. |
| **init**         | `fun(LazyPlugin)`                                         | `init` functions are always executed during startup                                                                                                                                                                                    |
| **config**       | `fun(LazyPlugin)` or `true` or `table`                    | `config` is executed when the plugin loads. You can also set to `true` or pass a `table`, that will be passed to `require("plugin").setup(opts)`                                                                                       |
| **build**        | `fun(LazyPlugin)` or `string` or a list of build commands | `build` is executed when a plugin is installed or updated. If it's a string it will be ran as a shell command. When prefixed with `:` it is a Neovim command. You can also specify a list to executed multiple build commands          |
| **branch**       | `string?`                                                 | Branch of the repository                                                                                                                                                                                                               |
| **tag**          | `string?`                                                 | Tag of the repository                                                                                                                                                                                                                  |
| **commit**       | `string?`                                                 | Commit of the repository                                                                                                                                                                                                               |
| **version**      | `string?`                                                 | Version to use from the repository. Full [Semver](https://devhints.io/semver) ranges are supported                                                                                                                                     |
| **pin**          | `boolean?`                                                | When `true`, this plugin will not be included in updates                                                                                                                                                                               |
| **event**        | `string?` or `string[]`                                   | Lazy-load on event. Events can be specified as `BufEnter` or with a pattern like `BufEnter *.lua`                                                                                                                                      |
| **cmd**          | `string?` or `string[]`                                   | Lazy-load on command                                                                                                                                                                                                                   |
| **ft**           | `string?` or `string[]`                                   | Lazy-load on filetype                                                                                                                                                                                                                  |
| **keys**         | `string?` or `string[]` or `LazyKeys[]`                   | Lazy-load on key mapping                                                                                                                                                                                                               |
| **module**       | `false?`                                                  | Do not automatically load this Lua module when it's required somewhere                                                                                                                                                                 |
| **priority**     | `number?`                                                 | Only useful for **start** plugins (`lazy=false`) to force loading certain plugins first. Default priority is `50`. It's recommended to set this to a high number for colorschemes.                                                     |

### Lazy Loading

**lazy.nvim** automagically lazy-loads Lua modules, so it is not needed to
specify `module=...` everywhere in your plugin specification. This mean that if
you have a plugin `A` that is lazy-loaded and a plugin `B` that requires a
module of plugin `A`, then plugin `A` will be loaded on demand as expected.

If you don't want this behavior for a certain plugin, you can specify that with `module=false`.
You can then manually load the plugin with `:Lazy load foobar.nvim`.

You can configure **lazy.nvim** to lazy-load all plugins by default with `config.defaults.lazy = true`.

Additionally, you can also lazy-load on **events**, **commands**,
**file types** and **key mappings**.

Plugins will be lazy-loaded when one of the following is `true`:

- the plugin only exists as a dependency in your spec
- it has an `event`, `cmd`, `ft` or `keys` key
- `config.defaults.lazy == true`

#### 🌈 Colorschemes

Colorscheme plugins can be configured with `lazy=true`. The plugin will automagically load
when doing `colorscheme foobar`.

> **NOTE:** since **start** plugins can possibly change existing highlight groups,
> it's important to make sure that your main **colorscheme** is loaded first.
> To ensure this you can use the `priority=1000` field. **_(see the examples)_**

#### ⌨️ Lazy Key Mappings

The `keys` property can be a `string` or `string[]` for simple normal-mode mappings, or it
can be a `LazyKeys` table with the following key-value pairs:

- **[1]**: (`string`) lhs **_(required)_**
- **[2]**: (`string|fun()`) rhs **_(optional)_**
- **mode**: (`string|string[]`) mode **_(optional, defaults to `"n"`)_**
- any other option valid for `vim.keymap.set`

Key mappings will load the plugin the first time they get executed.

When `[2]` is `nil`, then the real mapping has to be created by the `config()` function.

```lua
-- Example for neo-tree.nvim
{
  "nvim-neo-tree/neo-tree.nvim",
    keys = {
      { "<leader>ft", "<cmd>Neotree toggle<cr>", desc = "NeoTree" },
    },
    config = function()
      require("neo-tree").setup()
    end,
}
```

### Versioning

If you want to install a specific revision of a plugin, you can use `commit`,
`tag`, `branch`, `version`.

The `version` property supports [Semver](https://semver.org/) ranges.

<details>
<summary>Click to see some examples</summary>

- `*`: latest stable version (this excludes pre-release versions)
- `1.2.x`: any version that starts with `1.2`, such as `1.2.0`, `1.2.3`, etc.
- `^1.2.3`: any version that is compatible with `1.2.3`, such as `1.3.0`, `1.4.5`, etc., but not `2.0.0`.
- `~1.2.3`: any version that is compatible with `1.2.3`, such as `1.2.4`, `1.2.5`, but not `1.3.0`.
- `>1.2.3`: any version that is greater than `1.2.3`, such as `1.3.0`, `1.4.5`, etc.
- `>=1.2.3`: any version that is greater than or equal to `1.2.3`, such as `1.2.3`, `1.3.0`, `1.4.5`, etc.
- `<1.2.3`: any version that is less than `1.2.3`, such as `1.1.0`, `1.0.5`, etc.
- `<=1.2.3`: any version that is less than or equal to `1.2.3`, such as `1.2.3`, `1.1.0`, `1.0.5`, etc

</details>

You can set `config.defaults.version = "*"` to install the latest stable
version of plugins that support Semver.

### Examples

<!-- spec:start -->

```lua
return {
  -- the colorscheme should be available when starting Neovim
  {
    "folke/tokyonight.nvim",
    lazy = false, -- make sure we load this during startup if it is your main colorscheme
    priority = 1000, -- make sure to load this before all the other start plugins
    config = function()
      -- load the colorscheme here
      vim.cmd([[colorscheme tokyonight]])
    end,
  },

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

  -- the above could also be written as:
  {
    "nvim-neorg/neorg",
    ft = "norg",
    config = true, -- run require("neorg").setup()
  },

  -- or set a custom config:
  {
    "nvim-neorg/neorg",
    ft = "norg",
    config = { foo = "bar" }, -- run require("neorg").setup({foo = "bar"})
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
    -- mode is `n` by default. For more advanced options, check the section on key mappings
    keys = { "<C-a>", { "<C-x>", mode = "n" } },
  },

  -- local plugins need to be explicitly configured with dir
  { dir = "~/projects/secret.nvim" },

  -- you can use a custom url to fetch a plugin
  { url = "git@github.com:folke/noice.nvim.git" },

  -- local plugins can also be configure with the dev option.
  -- This will use {config.dev.path}/noice.nvim/ instead of fetching it from Github
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
    log = { "--since=3 days ago" }, -- show commits from the last 3 days
    timeout = 120, -- kill processes that take more than 2 minutes
    url_format = "https://github.com/%s.git",
  },
  dev = {
    -- directory where you store your local plugin projects
    path = "~/projects",
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
    -- a number <1 is a percentage., >1 is a fixed size
    size = { width = 0.8, height = 0.8 },
    -- The border to use for the UI window. Accepts same border values as |nvim_open_win()|.
    border = "none",
    icons = {
      loaded = "●",
      not_loaded = "○",
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
      lazy = "鈴 ",
      list = {
        "●",
        "➜",
        "★",
        "‒",
      },
    },
    throttle = 20, -- how frequently should the ui process render events
    custom_keys = {
      -- you can define custom key maps here.
      -- To disable one of the defaults, set it to false

      -- open lazygit log
      ["<localleader>l"] = function(plugin)
        require("lazy.util").open_cmd({ "lazygit", "log" }, {
          cwd = plugin.dir,
          terminal = true,
          close_on_exit = true,
          enter = true,
        })
      end,

      -- open a terminal for the plugin dir
      ["<localleader>t"] = function(plugin)
        require("lazy.util").open_cmd({ vim.go.shell }, {
          cwd = plugin.dir,
          terminal = true,
          close_on_exit = true,
          enter = true,
        })
      end,
    },
  },
  diff = {
    -- diff command <d> can be one of:
    -- * browser: opens the github compare view. Note that this is always mapped to <K> as well,
    --   so you can have a different command for diff <d>
    -- * git: will run git diff and open a buffer with filetype git
    -- * terminal_git: will open a pseudo terminal with git diff
    -- * diffview.nvim: will open Diffview to show the diff
    cmd = "git",
  },
  checker = {
    -- automatically check for plugin updates
    enabled = false,
    concurrency = nil, ---@type number? set to 1 to check for updates very slowly
    notify = true, -- get a notification when new updates are found
    frequency = 3600, -- check for updates every hour
  },
  change_detection = {
    -- automatically check for config file changes and reload the ui
    enabled = true,
    notify = true, -- get a notification when changes are found
  },
  performance = {
    cache = {
      enabled = true,
      path = vim.fn.stdpath("cache") .. "/lazy/cache",
      -- Once one of the following events triggers, caching will be disabled.
      -- To cache all modules, set this to `{}`, but that is not recommended.
      -- The default is to disable on:
      --  * VimEnter: not useful to cache anything else beyond startup
      --  * BufReadPre: this will be triggered early when opening a file from the command line directly
      disable_events = { "VimEnter", "BufReadPre" },
      ttl = 3600 * 24 * 5, -- keep unused modules for up to 5 days
    },
    reset_packpath = true, -- reset the package path to improve startup time
    rtp = {
      reset = true, -- reset the runtime path to $VIMRUNTIME and your config directory
      ---@type string[]
      paths = {}, -- add any custom paths here that you want to indluce in the rtp
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

<details>
<summary>If you don't want to use a Nerd Font, you can replace the icons with Unicode symbols.</summary>

```lua
{
  ui = {
    icons = {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🗝",
      plugin = "🔌",
      runtime = "💻",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
}
```

</details>

## 🚀 Usage

Plugins are managed with the `:Lazy` command.
Open the help with `<?>` to see all the key mappings.

You can press `<CR>` on a plugin to show its details. Most properties
can be hovered with `<K>` to open links, help files, readmes,
git commits and git issues.

Lazy can automatically check for updates in the background. This feature
can be enabled with `config.checker.enabled = true`.

Any operation can be started from the UI, with a sub command or an API function:

<!-- commands:start -->

| Command                   | Lua                              | Description                                                                                                                                          |
| ------------------------- | -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- |
| `:Lazy check [plugins]`   | `require("lazy").check(opts?)`   | Check for updates and show the log (git fetch)                                                                                                       |
| `:Lazy clean [plugins]`   | `require("lazy").clean(opts?)`   | Clean plugins that are no longer needed                                                                                                              |
| `:Lazy clear`             | `require("lazy").clear()`        | Clear finished tasks                                                                                                                                 |
| `:Lazy debug`             | `require("lazy").debug()`        | Show debug information                                                                                                                               |
| `:Lazy help`              | `require("lazy").help()`         | Toggle this help page                                                                                                                                |
| `:Lazy home`              | `require("lazy").home()`         | Go back to plugin list                                                                                                                               |
| `:Lazy install [plugins]` | `require("lazy").install(opts?)` | Install missing plugins                                                                                                                              |
| `:Lazy load {plugins}`    | `require("lazy").load(opts)`     | Load a plugin that has not been loaded yet. Similar to `:packadd`. Like `:Lazy load foo.nvim`                                                        |
| `:Lazy log [plugins]`     | `require("lazy").log(opts?)`     | Show recent updates                                                                                                                                  |
| `:Lazy profile`           | `require("lazy").profile()`      | Show detailed profiling                                                                                                                              |
| `:Lazy restore [plugins]` | `require("lazy").restore(opts?)` | Updates all plugins to the state in the lockfile. For a single plugin: restore it to the state in the lockfile or to a given commit under the cursor |
| `:Lazy sync [plugins]`    | `require("lazy").sync(opts?)`    | Run install, clean and update                                                                                                                        |
| `:Lazy update [plugins]`  | `require("lazy").update(opts?)`  | Update plugins. This will also update the lockfile                                                                                                   |

<!-- commands:end -->

Any command can have a **bang** to make the command wait till it finished. For example,
if you want to sync lazy from the cmdline, you can use:

```shell
$ nvim --headless "+Lazy! sync" +qa
```

`opts` is a table with the following key-values:

- **wait**: when true, then the call will wait till the operation completed
- **show**: when false, the UI will not be shown
- **plugins**: a list of plugin names to run the operation on
- **concurrency**: limit the `number` of concurrently running tasks

Stats API (`require("lazy").stats()`):

<!-- stats:start -->

```lua
{
  -- startuptime in milliseconds till UIEnter
  startuptime = 0,
  -- when true, startuptime is the accurate cputime for the Neovim process. (Linux & Macos)
  -- this is more accurate than `nvim --startuptime`, and as such will be slightly higher
  -- when false, startuptime is calculated based on a delta with a timestamp when lazy started.
  startuptime_cputime = false,
  count = 0, -- total number of plugins
  loaded = 0, -- number of loaded plugins
}
```

<!-- stats:end -->

**lazy.nvim** provides a statusline component that you can use to show the number of pending updates.
Make sure to enable `config.checker.enabled = true` to make this work.

<details>
<summary>Example of configuring <a href="https://github.com/nvim-lualine/lualine.nvim">lualine.nvim</a></summary>

```lua
require("lualine").setup({
  sections = {
    lualine_x = {
      {
        require("lazy.status").updates,
        cond = require("lazy.status").has_updates,
        color = { fg = "#ff9e64" },
      },
    },
  },
})

```

</details>

### 📆 User Events

The following user events will be triggered:

- **LazyDone**: when lazy has finished starting up and loaded your config
- **LazySync**: after running sync
- **LazyInstall**: after an install
- **LazyUpdate**: after an update
- **LazyClean**: after a clean
- **LazyCheck**: after checking for updates
- **LazyLog**: after running log
- **LazyReload**: triggered by change detection after reloading plugin specs
- **VeryLazy**: triggered after `LazyDone` and processing `VimEnter` auto commands
- **LazyVimStarted**: triggered after `UIEnter` when `require("lazy").stats().startuptime` has been calculated.
  Useful to update the startuptime on your dashboard.

## 🔒 Lockfile `lazy-lock.json`

After every **update**, the local lockfile is updated with the installed revisions.
It is recommended to have this file under version control.

If you use your Neovim config on multiple machines, using the lockfile, you can
ensure that the same version of every plugin is installed.

If you are on another machine, you can do `:Lazy restore`, to update all your plugins to
the version from the lockfile.

## ⚡ Performance

Great care has been taken to make the startup code (`lazy.core`) as efficient as possible.
During startup, all Lua files used before `VimEnter` or `BufReadPre` are byte-compiled and cached,
similar to what [impatient.nvim](https://github.com/lewis6991/impatient.nvim) does.

My config for example loads in about `11ms` with `93` plugins. I do a lot of lazy-loading though :)

**lazy.nvim** comes with an advanced profiler `:Lazy profile` to help you improve performance.
The profiling view shows you why and how long it took to load your plugins.

![image](https://user-images.githubusercontent.com/292349/208301766-5c400561-83c3-4811-9667-1ec4bb3c43b8.png)

## 🪲 Debug

See an overview of active lazy-loading handlers and what's in the module cache

![image](https://user-images.githubusercontent.com/292349/208301790-7eedbfa5-d202-4e70-852e-de68aa47233b.png)

## ▶️ Startup Sequence

**lazy.nvim** does **NOT** use Neovim packages and even disables plugin loading
completely (`vim.go.loadplugins = false`). It takes over the complete
startup sequence for more flexibility and better performance.

In practice this means that step 10 of [Neovim Initialization](https://neovim.io/doc/user/starting.html#initialization) is done by Lazy:

1. all the plugins' `init()` functions are executed
2. all plugins with `lazy=false` are loaded. This includes sourcing `/plugin` and `/ftdetect` files. (`/after` will not be sourced yet)
3. all files from `/plugin` and `/ftdetect` directories in you rtp are sourced (excluding `/after`)
4. all `/after/plugin` files are sourced (this inludes `/after` from plugins)

Files from runtime directories are always sourced in alphabetical order.

## 📂 Structuring Your Plugins

Some users may want to split their plugin specs in multiple files.
Instead of passing a spec table to `setup()`, you can use a Lua module.
The specs from the **module** and any top-level **sub-modules** will be merged together in the final spec,
so it is not needed to add `require` calls in your main plugin file to the other files.

The benefits of using this approach:

- simple to **add** new plugin specs. Just create a new file in your plugins module.
- allows for **caching** of all your plugin specs. This becomes important if you have a lot of smaller plugin specs.
- spec changes will automatically be **reloaded** when they're updated, so the `:Lazy` UI is always up to date

Example:

- `~/.config/nvim/init.lua`

```lua
require("lazy").setup("plugins")
```

- `~/.config/nvim/lua/plugins.lua` or `~/.config/nvim/lua/plugins/init.lua` **_(this file is optional)_**

```lua
return {
  "folke/neodev.nvim",
    "folke/which-key.nvim",
    { "folke/neoconf.nvim", cmd = "Neoconf" },
}
```

- any lua file in `~/.config/nvim/lua/plugins/*.lua` will be automatically merged in the main plugin spec

For a real-life example, you can check my personal dots:

- [init.lua](https://github.com/folke/dot/blob/master/config/nvim/init.lua) where I require `config.lazy`
- [config.lazy](https://github.com/folke/dot/blob/master/config/nvim/lua/config/lazy.lua) where I bootstrap and setup **lazy.nvim**
- [config.plugins](https://github.com/folke/dot/blob/master/config/nvim/lua/config/plugins/init.lua) is my main plugin config module
- Any submodule of [config.plugins (submodules)](https://github.com/folke/dot/tree/master/config/nvim/lua/config/plugins) will be automatically loaded as well.

## 📦 Migration Guide

### [packer.nvim](https://github.com/wbthomason/packer.nvim)

- `setup` ➡️ `init`
- `requires` ➡️ `dependencies`
- `as` ➡️ `name`
- `opt` ➡️ `lazy`
- `run` ➡️ `build`
- `lock` ➡️ `pin`
- `disable=true` ➡️ `enabled = false`
- `tag='*'` ➡️ `version="*"`
- `after` ℹ️ **_not needed_** for most use-cases. Use `dependencies` otherwise.
- `wants` ℹ️ **_not needed_** for most use-cases. Use `dependencies` otherwise.
- `config` don't support string type, use `fun(LazyPlugin)` instead.
- `module` is auto-loaded. No need to specify
- `keys` spec is [different](#%EF%B8%8F-lazy-key-mappings)

With packer `wants`, `requires` and `after` can be used to manage dependencies.
With lazy, this isn't needed for most of the lua dependencies. They can be installed just like normal plugins
(even with `lazy=true`) and will be loaded when other plugins need them.
The `dependencies` key can be used to group those required plugins with the one that requires them.
The plugins which are added as `dependencies` will always be lazy-loaded and loaded when the plugin is loaded.

### [paq-nvim](https://github.com/savq/paq-nvim)

- `as` ➡️ `name`
- `opt` ➡️ `lazy`
- `run` ➡️ `build`

## ❌ Uninstalling

To uninstall **lazy.nvim**, you need to remove the following files and directories:

- **data**: `~/.local/share/nvim/lazy`
- **state**: `~/.local/state/nvim/lazy`
- **lockfile**: `~/.config/nvim/lazy-lock.json`

> paths can differ if you changed `XDG` environment variables.

## 🌈 Highlight Groups

<details>
<summary>Click to see all highlight groups</summary>

<!-- colors:start -->

| Highlight Group       | Default Group              | Description                                         |
| --------------------- | -------------------------- | --------------------------------------------------- |
| **LazyButton**        | **_CursorLine_**           |                                                     |
| **LazyButtonActive**  | **_Visual_**               |                                                     |
| **LazyComment**       | **_Comment_**              |                                                     |
| **LazyCommit**        | **_@variable.builtin_**    | commit ref                                          |
| **LazyCommitIssue**   | **_Number_**               |                                                     |
| **LazyCommitScope**   | **_Italic_**               | conventional commit scope                           |
| **LazyCommitType**    | **_Title_**                | conventional commit type                            |
| **LazyDir**           | **_@text.reference_**      | directory                                           |
| **LazyH1**            | **_IncSearch_**            | home button                                         |
| **LazyH2**            | **_Bold_**                 | titles                                              |
| **LazyNoCond**        | **_DiagnosticWarn_**       | unloaded icon for a plugin where `cond()` was false |
| **LazyNormal**        | **_NormalFloat_**          |                                                     |
| **LazyProgressDone**  | **_Constant_**             | progress bar done                                   |
| **LazyProgressTodo**  | **_LineNr_**               | progress bar todo                                   |
| **LazyProp**          | **_Conceal_**              | property                                            |
| **LazyReasonCmd**     | **_Operator_**             |                                                     |
| **LazyReasonEvent**   | **_Constant_**             |                                                     |
| **LazyReasonFt**      | **_Character_**            |                                                     |
| **LazyReasonKeys**    | **_Statement_**            |                                                     |
| **LazyReasonPlugin**  | **_Special_**              |                                                     |
| **LazyReasonRuntime** | **_@macro_**               |                                                     |
| **LazyReasonSource**  | **_Character_**            |                                                     |
| **LazyReasonStart**   | **_@field_**               |                                                     |
| **LazySpecial**       | **_@punctuation.special_** |                                                     |
| **LazyTaskError**     | **_ErrorMsg_**             | task errors                                         |
| **LazyTaskOutput**    | **_MsgArea_**              | task output                                         |
| **LazyUrl**           | **_@text.reference_**      | url                                                 |
| **LazyValue**         | **_@string_**              | value of a property                                 |

<!-- colors:end -->

</details>

## 📦 Other Neovim Plugin Managers in Lua

- [packer.nvim](https://github.com/wbthomason/packer.nvim)
- [paq-nvim](https://github.com/savq/paq-nvim)
- [neopm](https://github.com/ii14/neopm)
- [dep](https://github.com/chiyadev/dep)
- [optpack.nvim](https://github.com/notomo/optpack.nvim)
- [pact.nvim](https://github.com/rktjmp/pact.nvim)
