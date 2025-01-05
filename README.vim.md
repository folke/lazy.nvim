# 📰 What's new?

## 11.x

- **New Website**: There's a whole new website with a fresh look and improved documentation.
  Check it out at [https://lazy.folke.io](https://lazy.folke.io/).
  The GitHub `README.md` has been updated to point to the new website.
  The `vimdoc` contains all the information that is available on the website.

- **Spec Resolution & Merging**: the code that resolves a final spec from a plugin's fragments has been rewritten.
  This should be a tiny bit faster, but more importantly, fixes some issues and is easier to maintain.

- [Packages](https://lazy.folke.io/packages) can now specify their dependencies and configuration using one of:

  - **Lazy**: `lazy.lua` file
  - **Rockspec**: [luarocks](https://luarocks.org/) `*-scm-1.rockspec` [file](https://github.com/luarocks/luarocks/wiki/Rockspec-format)
  - **Packspec**: `pkg.json` (experimental, since the [format](https://github.com/neovim/packspec/issues/41) is not quite there yet)

  Related _lazy.nvim_ options:

  ```lua
  {
    pkg = {
      enabled = true,
      cache = vim.fn.stdpath("state") .. "/lazy/pkg-cache.lua",
      -- the first package source that is found for a plugin will be used.
      sources = {
        "lazy",
        "rockspec", -- will only be used when rocks.enabled is true
        "packspec",
      },
    },
    rocks = {
      enabled = true,
      root = vim.fn.stdpath("data") .. "/lazy-rocks",
      server = "https://nvim-neorocks.github.io/rocks-binaries/",
    },
  }
  ```

- Installing [neorg](https://github.com/nvim-neorg/neorg) is now as simple as:

  ```lua
  { "nvim-neorg/neorg", opts = {} }
  ```

- Packages are not limited to just Neovim plugins. You can install any **luarocks** package, like:

  ```lua
  { "https://github.com/lubyk/yaml" }
  ```

  Luarocks packages without a `/lua` directory are never lazy-loaded, since it's just a library.

- `build` functions or `*.lua` build files (like `build.lua`) now run asynchronously.
  You can use `coroutine.yield(status_msg)` to show progress.
  Yielding will also schedule the next `resume` to run in the next tick,
  so you can do long-running tasks without blocking Neovim.

# 🚀 Getting Started

**lazy.nvim** is a modern plugin manager for Neovim.

![image](https://user-images.githubusercontent.com/292349/208301737-68fb279c-ba70-43ef-a369-8c3e8367d6b1.png)

## ✨ Features

- 📦 Manage all your Neovim plugins with a powerful UI
- 🚀 Fast startup times thanks to automatic caching and bytecode compilation of Lua modules
- 💾 Partial clones instead of shallow clones
- 🔌 Automatic lazy-loading of Lua modules and lazy-loading on events, commands, filetypes, and key mappings
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
- [luarocks](https://luarocks.org/) to install rockspecs.
  You can remove `rockspec` from `opts.pkg.sources` to disable this feature.

# 🛠️ Installation

There are multiple ways to install **lazy.nvim**.
The **Structured Setup** is the recommended way, but you can also use the **Single File Setup**
if you prefer to keep everything in your `init.lua`.

Please refer to the [Configuration](/configuration) section for an overview of all available options.

:::tip

It is recommended to run `:checkhealth lazy` after installation.

:::

:::note

In what follows `~/.config/nvim` is your Neovim configuration directory.
On Windows, this is usually `~\AppData\Local\nvim`.
To know the correct path for your system, run `:echo stdpath('config')`.

:::

## Structured Setup

```lua
require("config.lazy")
```

```lua
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  -- highlight-start
  spec = {
    -- import your plugins
    { import = "plugins" },
  },
  -- highlight-end
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})
```

You can then create your plugin specs in `~/.config/nvim/lua/plugins/`.
Each file should return a table with the plugins you want to install.

For more info see [Structuring Your Plugins](/usage/structuring)

<pre>
~/.config/nvim
├── lua
│   ├── config
│   │   └── lazy.lua
│   └── plugins
│       ├── spec1.lua
│       ├── **
│       └── spec2.lua
└── init.lua
</pre>

## Single File Setup

```lua
-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- Make sure to setup `mapleader` and `maplocalleader` before
-- loading lazy.nvim so that mappings are correct.
-- This is also a good place to setup other settings (vim.opt)
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Setup lazy.nvim
require("lazy").setup({
  -- highlight-start
  spec = {
    -- add your plugins here
  },
  -- highlight-end
  -- Configure any other settings here. See the documentation for more details.
  -- colorscheme that will be used when installing plugins.
  install = { colorscheme = { "habamax" } },
  -- automatically check for plugin updates
  checker = { enabled = true },
})
```

# 🔌 Plugin Spec

## Spec Source

| Property  | Type       | Description                                                                                                          |
| --------- | ---------- | -------------------------------------------------------------------------------------------------------------------- |
| **\[1\]** | `string?`  | Short plugin url. Will be expanded using [`config.git.url_format`](../configuration/). Can also be a `url` or `dir`. |
| **dir**   | `string?`  | A directory pointing to a local plugin                                                                               |
| **url**   | `string?`  | A custom git url where the plugin is hosted                                                                          |
| **name**  | `string?`  | A custom name for the plugin used for the local plugin directory and as the display name                             |
| **dev**   | `boolean?` | When `true`, a local plugin directory will be used instead. See [`config.dev`](../configuration/)                    |

A valid spec should define one of `[1]`, `dir` or `url`.

## Spec Loading

| Property         | Type                                    | Description                                                                                                                                                                                                                            |
| ---------------- | --------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **dependencies** | `LazySpec[]`                            | A list of plugin names or plugin specs that should be loaded when the plugin loads. Dependencies are always lazy-loaded unless specified otherwise. When specifying a name, make sure the plugin spec has been defined somewhere else. |
| **enabled**      | `boolean?` or `fun():boolean`           | When `false`, or if the `function` returns false, then this plugin will not be included in the spec                                                                                                                                    |
| **cond**         | `boolean?` or `fun(LazyPlugin):boolean` | Behaves the same as `enabled`, but won't uninstall the plugin when the condition is `false`. Useful to disable some plugins in vscode, or firenvim for example.                                                                        |
| **priority**     | `number?`                               | Only useful for **start** plugins (`lazy=false`) to force loading certain plugins first. Default priority is `50`. It's recommended to set this to a high number for colorschemes.                                                     |

## Spec Setup

| Property   | Type                                                                 | Description                                                                                                                                                                                                                                                                                                                               |
| ---------- | -------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **init**   | `fun(LazyPlugin)`                                                    | `init` functions are always executed during startup. Mostly useful for setting `vim.g.*` configuration used by **Vim** plugins startup                                                                                                                                                                                                            |
| **opts**   | `table` or `fun(LazyPlugin, opts:table)`                             | `opts` should be a table (will be merged with parent specs), return a table (replaces parent specs) or should change a table. The table will be passed to the `Plugin.config()` function. Setting this value will imply `Plugin.config()`                                                                                                 |
| **config** | `fun(LazyPlugin, opts:table)` or `true`                              | `config` is executed when the plugin loads. The default implementation will automatically run `require(MAIN).setup(opts)` if `opts` or `config = true` is set. Lazy uses several heuristics to determine the plugin's `MAIN` module automatically based on the plugin's **name**. _(`opts` is the recommended way to configure plugins)_. |
| **main**   | `string?`                                                            | You can specify the `main` module to use for `config()` and `opts()`, in case it can not be determined automatically. See `config()`                                                                                                                                                                                                      |
| **build**  | `fun(LazyPlugin)` or `string` or `false` or a list of build commands | `build` is executed when a plugin is installed or updated. See [Building](/developers#building) for more information.                                                                                                                                                                                                                     |

Always use `opts` instead of `config` when possible. `config` is almost never needed.

:::tip[GOOD]

```lua
{ "folke/todo-comments.nvim", opts = {} },
```

:::

:::danger[BAD]

```lua
{
  "folke/todo-comments.nvim",
  config = function()
    require("todo-comments").setup({})
  end,
},
```

:::

## Spec Lazy Loading

| Property  | Type                                                                                                                                | Description                                                                                                                                                                                    |
| --------- | ----------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **lazy**  | `boolean?`                                                                                                                          | When `true`, the plugin will only be loaded when needed. Lazy-loaded plugins are automatically loaded when their Lua modules are `required`, or when one of the lazy-loading handlers triggers |
| **event** | `string?` or `string[]` or `fun(self:LazyPlugin, event:string[]):string[]` or `{event:string[]\|string, pattern?:string[]\|string}` | Lazy-load on event. Events can be specified as `BufEnter` or with a pattern like `BufEnter *.lua`                                                                                              |
| **cmd**   | `string?` or `string[]` or `fun(self:LazyPlugin, cmd:string[]):string[]`                                                            | Lazy-load on command                                                                                                                                                                           |
| **ft**    | `string?` or `string[]` or `fun(self:LazyPlugin, ft:string[]):string[]`                                                             | Lazy-load on filetype                                                                                                                                                                          |
| **keys**  | `string?` or `string[]` or `LazyKeysSpec[]` or `fun(self:LazyPlugin, keys:string[]):(string \| LazyKeysSpec)[]`                     | Lazy-load on [key mapping](/spec/lazy_loading#%EF%B8%8F-lazy-key-mappings)                                                                                                                     |

Refer to the [Lazy Loading](./lazy_loading.md) section for more information.

## Spec Versioning

| Property       | Type                                         | Description                                                                                        |
| -------------- | -------------------------------------------- | -------------------------------------------------------------------------------------------------- |
| **branch**     | `string?`                                    | Branch of the repository                                                                           |
| **tag**        | `string?`                                    | Tag of the repository                                                                              |
| **commit**     | `string?`                                    | Commit of the repository                                                                           |
| **version**    | `string?` or `false` to override the default | Version to use from the repository. Full [Semver](https://devhints.io/semver) ranges are supported |
| **pin**        | `boolean?`                                   | When `true`, this plugin will not be included in updates                                           |
| **submodules** | `boolean?`                                   | When false, git submodules will not be fetched. Defaults to `true`                                 |

Refer to the [Versioning](./versioning.md) section for more information.

## Spec Advanced

| Property     | Type       | Description                                                                                                                                                                                                                                                                                                                                              |
| ------------ | ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **optional** | `boolean?` | When a spec is tagged optional, it will only be included in the final spec, when the same plugin has been specified at least once somewhere else without `optional`. This is mainly useful for Neovim distros, to allow setting options on plugins that may/may not be part of the user's plugins.                                                       |
| **specs**    | `LazySpec` | A list of plugin specs defined in the scope of the plugin. This is mainly useful for Neovim distros, to allow setting options on plugins that may/may not be part of the user's plugins. When the plugin is disabled, none of the scoped specs will be included in the final spec. Similar to `dependencies` without the automatic loading of the specs. |
| **module**   | `false?`   | Do not automatically load this Lua module when it's required somewhere                                                                                                                                                                                                                                                                                   |
| **import**   | `string?`  | Import the given spec module.                                                                                                                                                                                                                                                                                                                            |

## Examples

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
    -- options for neorg. This will automatically call `require("neorg").setup(opts)`
    opts = {
      load = {
        ["core.defaults"] = {},
      },
    },
  },

  {
    "dstein64/vim-startuptime",
    -- lazy-load on a command
    cmd = "StartupTime",
    -- init is called during startup. Configuration for vim plugins typically should be set in an init function
    init = function()
      vim.g.startuptime_tries = 10
    end,
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

  -- if some code requires a module from an unloaded plugin, it will be automatically loaded.
  -- So for api plugins like devicons, we can always set lazy=true
  { "nvim-tree/nvim-web-devicons", lazy = true },

  -- you can use the VeryLazy event for things that can
  -- load later and are not important for the initial UI
  { "stevearc/dressing.nvim", event = "VeryLazy" },

  {
    "Wansmer/treesj",
    keys = {
      { "J", "<cmd>TSJToggle<cr>", desc = "Join Toggle" },
    },
    opts = { use_default_keymaps = false, max_join_length = 150 },
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

  -- local plugins can also be configured with the dev option.
  -- This will use {config.dev.path}/noice.nvim/ instead of fetching it from GitHub
  -- With the dev option, you can easily switch between the local and installed version of a plugin
  { "folke/noice.nvim", dev = true },
}
```

## Lazy Loading

**lazy.nvim** automagically lazy-loads Lua modules. This means that if
you have a plugin `A` that is lazy-loaded and a plugin `B` that requires a
module of plugin `A`, then plugin `A` will be loaded on demand as expected.

:::tip

You can configure **lazy.nvim** to lazy-load all plugins by default with `config.defaults.lazy = true`.
Make sure you've configured lazy-loading, for your plugins to avoid unexpected behavior.
Only do this if you know what you are doing, as it can lead to unexpected behavior.

:::

Additionally, you can also lazy-load on **events**, **commands**,
**file types** and **key mappings**.

Plugins will be lazy-loaded when one of the following is `true`:

- The plugin only exists as a dependency in your spec
- It has an `event`, `cmd`, `ft` or `keys` key
- `config.defaults.lazy == true`

### 🌈 Colorschemes

Colorscheme plugins can be configured with `lazy=true`. The plugin will automagically load
when doing `colorscheme foobar`.

:::warning

since **start** plugins (`lazy=false`) can possibly change existing highlight groups,
it's important to make sure that your main **colorscheme** is loaded first.
To ensure this you can use the `priority=1000` field. **_(see the [examples](./examples.md))_**

:::

### ⌨️ Lazy Key Mappings

The `keys` property can be a `string` or `string[]` for simple normal-mode mappings, or it
can be a `LazyKeysSpec` table with the following key-value pairs:

- **[1]**: (`string`) lhs **_(required)_**
- **[2]**: (`string|fun()`) rhs **_(optional)_**
- **mode**: (`string|string[]`) mode **_(optional, defaults to `"n"`)_**
- **ft**: (`string|string[]`) `filetype` for buffer-local keymaps **_(optional)_**
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
    opts = {},
}
```

## Versioning

If you want to install a specific revision of a plugin, you can use `commit`,
`tag`, `branch`, `version`.

The `version` property supports [Semver](https://semver.org/) ranges.

:::tip

You can set `config.defaults.version = "*"` to install the latest stable
version of plugins that support Semver.

:::

### Examples

- `*`: latest stable version (this excludes pre-release versions)
- `1.2.x`: any version that starts with `1.2`, such as `1.2.0`, `1.2.3`, etc.
- `^1.2.3`: any version that is compatible with `1.2.3`, such as `1.3.0`, `1.4.5`, etc., but not `2.0.0`.
- `~1.2.3`: any version that is compatible with `1.2.3`, such as `1.2.4`, `1.2.5`, but not `1.3.0`.
- `>1.2.3`: any version that is greater than `1.2.3`, such as `1.3.0`, `1.4.5`, etc.
- `>=1.2.3`: any version that is greater than or equal to `1.2.3`, such as `1.2.3`, `1.3.0`, `1.4.5`, etc.
- `<1.2.3`: any version that is less than `1.2.3`, such as `1.1.0`, `1.0.5`, etc.
- `<=1.2.3`: any version that is less than or equal to `1.2.3`, such as `1.2.3`, `1.1.0`, `1.0.5`, etc

# 📦 Packages

**lazy.nvim** supports three ways for plugins to define their dependencies and configuration.

- **Lazy**: `lazy.lua` file
- **Rockspec**: [luarocks](https://luarocks.org/) `*-scm-1.rockspec` [file](https://github.com/luarocks/luarocks/wiki/Rockspec-format)
- **Packspec**: `pkg.json` (experimental, since the [format](https://github.com/neovim/packspec/issues/41) is not quite there yet)

You can enable/disable package sources with [`config.pkg.sources`](/configuration).
The order of sources is important, as the first source that finds a package will be used.

:::info

Package specs are always loaded in the scope of the plugin (using [specs](/spec#advanced)),
so that when the plugin is disabled, none of the specs are loaded.

:::

## Lazy

Using a `lazy.lua` file is the recommended way to define your plugin dependencies and configuration.
Syntax is the same as any plugin spec.

## Rockspec

When a plugin contains a `*-1.rockspec` file, **lazy.nvim** will automatically build the rock and its dependencies.

A **rockspec** will only be used if one of the following is true:

- the package does not have a `/lua` directory
- the package has a complex build step
- the package has dependencies (excluding `lua`)

## Packspec

Supports the [pkg.json](https://github.com/nvim-lua/nvim-package-specification/issues/41) format,
with a lazy extension in `lazy`.
`lazy` can contain any valid lazy spec fields. They will be added to the plugin's spec.

# ⚙️ Configuration

**lazy.nvim** comes with the following defaults:

```lua
{
  root = vim.fn.stdpath("data") .. "/lazy", -- directory where plugins will be installed
  defaults = {
    -- Set this to `true` to have all your plugins lazy-loaded by default.
    -- Only do this if you know what you are doing, as it can lead to unexpected behavior.
    lazy = false, -- should plugins be lazy-loaded?
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = nil, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
    -- default `cond` you can use to globally disable a lot of plugins
    -- when running inside vscode for example
    cond = nil, ---@type boolean|fun(self:LazyPlugin):boolean|nil
  },
  -- leave nil when passing the spec as the first argument to setup()
  spec = nil, ---@type LazySpec
  local_spec = true, -- load project specific .lazy.lua spec files. They will be added at the end of the spec.
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- lockfile generated after running update.
  ---@type number? limit the maximum amount of concurrent tasks
  concurrency = jit.os:find("Windows") and (vim.uv.available_parallelism() * 2) or nil,
  git = {
    -- defaults for the `Lazy log` command
    -- log = { "--since=3 days ago" }, -- show commits from the last 3 days
    log = { "-8" }, -- show the last 8 commits
    timeout = 120, -- kill processes that take more than 2 minutes
    url_format = "https://github.com/%s.git",
    -- lazy.nvim requires git >=2.19.0. If you really want to use lazy with an older version,
    -- then set the below to false. This should work, but is NOT supported and will
    -- increase downloads a lot.
    filter = true,
    -- rate of network related git operations (clone, fetch, checkout)
    throttle = {
      enabled = false, -- not enabled by default
      -- max 2 ops every 5 seconds
      rate = 2,
      duration = 5 * 1000, -- in ms
    },
    -- Time in seconds to wait before running fetch again for a plugin.
    -- Repeated update/check operations will not run again until this
    -- cooldown period has passed.
    cooldown = 0,
  },
  pkg = {
    enabled = true,
    cache = vim.fn.stdpath("state") .. "/lazy/pkg-cache.lua",
    -- the first package source that is found for a plugin will be used.
    sources = {
      "lazy",
      "rockspec", -- will only be used when rocks.enabled is true
      "packspec",
    },
  },
  rocks = {
    enabled = true,
    root = vim.fn.stdpath("data") .. "/lazy-rocks",
    server = "https://nvim-neorocks.github.io/rocks-binaries/",
    -- use hererocks to install luarocks?
    -- set to `nil` to use hererocks when luarocks is not found
    -- set to `true` to always use hererocks
    -- set to `false` to always use luarocks
    hererocks = nil,
  },
  dev = {
    -- Directory where you store your local plugin projects. If a function is used,
    -- the plugin directory (e.g. `~/projects/plugin-name`) must be returned.
    ---@type string | fun(plugin: LazyPlugin): string
    path = "~/projects",
    ---@type string[] plugins that match these patterns will use your local versions instead of being fetched from GitHub
    patterns = {}, -- For example {"folke"}
    fallback = false, -- Fallback to git when local plugin doesn't exist
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
    wrap = true, -- wrap the lines in the ui
    -- The border to use for the UI window. Accepts same border values as |nvim_open_win()|.
    border = "none",
    -- The backdrop opacity. 0 is fully opaque, 100 is fully transparent.
    backdrop = 60,
    title = nil, ---@type string only works when border is not "none"
    title_pos = "center", ---@type "center" | "left" | "right"
    -- Show pills on top of the Lazy window
    pills = true, ---@type boolean
    icons = {
      cmd = " ",
      config = "",
      debug = "●",
      event = " ",
      favorite = " ",
      ft = " ",
      init = " ",
      import = " ",
      keys = " ",
      lazy = "󰒲 ",
      loaded = "●",
      not_loaded = "○",
      plugin = " ",
      runtime = " ",
      require = "󰢱 ",
      source = " ",
      start = " ",
      task = "✔ ",
      list = {
        "●",
        "➜",
        "★",
        "‒",
      },
    },
    -- leave nil, to automatically select a browser depending on your OS.
    -- If you want to use a specific browser, you can define it here
    browser = nil, ---@type string?
    throttle = 1000 / 30, -- how frequently should the ui process render events
    custom_keys = {
      -- You can define custom key maps here. If present, the description will
      -- be shown in the help menu.
      -- To disable one of the defaults, set it to false.

      ["<localleader>l"] = {
        function(plugin)
          require("lazy.util").float_term({ "lazygit", "log" }, {
            cwd = plugin.dir,
          })
        end,
        desc = "Open lazygit log",
      },

      ["<localleader>i"] = {
        function(plugin)
          Util.notify(vim.inspect(plugin), {
            title = "Inspect " .. plugin.name,
            lang = "lua",
          })
        end,
        desc = "Inspect Plugin",
      },

      ["<localleader>t"] = {
        function(plugin)
          require("lazy.util").float_term(nil, {
            cwd = plugin.dir,
          })
        end,
        desc = "Open terminal in plugin dir",
      },
    },
  },
  -- Output options for headless mode
  headless = {
    -- show the output from process commands like git
    process = true,
    -- show log messages
    log = true,
    -- show task start/end
    task = true,
    -- use ansi colors
    colors = true,
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
    check_pinned = false, -- check for pinned packages that can't be updated
  },
  change_detection = {
    -- automatically check for config file changes and reload the ui
    enabled = true,
    notify = true, -- get a notification when changes are found
  },
  performance = {
    cache = {
      enabled = true,
    },
    reset_packpath = true, -- reset the package path to improve startup time
    rtp = {
      reset = true, -- reset the runtime path to $VIMRUNTIME and your config directory
      ---@type string[]
      paths = {}, -- add any custom paths here that you want to includes in the rtp
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
    enabled = true,
    root = vim.fn.stdpath("state") .. "/lazy/readme",
    files = { "README.md", "lua/**/README.md" },
    -- only generate markdown helptags for plugins that don't have docs
    skip_if_doc_exists = true,
  },
  state = vim.fn.stdpath("state") .. "/lazy/state.json", -- state info for checker and other things
  -- Enable profiling of lazy.nvim. This will add some overhead,
  -- so only enable this when you are debugging lazy.nvim
  profiling = {
    -- Enables extra stats on the debug tab related to the loader cache.
    -- Additionally gathers stats about all package.loaders
    loader = false,
    -- Track each new require in the Lazy profiling tab
    require = false,
  },
}
```

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
      require = "🌙",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
}
```

</details>

## 🌈 Highlight Groups

| Highlight Group | Default Group | Description |
| --- | --- | --- |
| **LazyBold** | `{ bold = true }` |  |
| **LazyButton** | ***CursorLine*** |  |
| **LazyButtonActive** | ***Visual*** |  |
| **LazyComment** | ***Comment*** |  |
| **LazyCommit** | ***@variable.builtin*** | commit ref |
| **LazyCommitIssue** | ***Number*** |  |
| **LazyCommitScope** | ***Italic*** | conventional commit scope |
| **LazyCommitType** | ***Title*** | conventional commit type |
| **LazyDimmed** | ***Conceal*** | property |
| **LazyDir** | ***@markup.link*** | directory |
| **LazyError** | ***DiagnosticError*** | task errors |
| **LazyH1** | ***IncSearch*** | home button |
| **LazyH2** | ***Bold*** | titles |
| **LazyInfo** | ***DiagnosticInfo*** | task errors |
| **LazyItalic** | `{ italic = true }` |  |
| **LazyLocal** | ***Constant*** |  |
| **LazyNoCond** | ***DiagnosticWarn*** | unloaded icon for a plugin where `cond()` was false |
| **LazyNormal** | ***NormalFloat*** |  |
| **LazyProgressDone** | ***Constant*** | progress bar done |
| **LazyProgressTodo** | ***LineNr*** | progress bar todo |
| **LazyProp** | ***Conceal*** | property |
| **LazyReasonCmd** | ***Operator*** |  |
| **LazyReasonEvent** | ***Constant*** |  |
| **LazyReasonFt** | ***Character*** |  |
| **LazyReasonImport** | ***Identifier*** |  |
| **LazyReasonKeys** | ***Statement*** |  |
| **LazyReasonPlugin** | ***Special*** |  |
| **LazyReasonRequire** | ***@variable.parameter*** |  |
| **LazyReasonRuntime** | ***@macro*** |  |
| **LazyReasonSource** | ***Character*** |  |
| **LazyReasonStart** | ***@variable.member*** |  |
| **LazySpecial** | ***@punctuation.special*** |  |
| **LazyTaskOutput** | ***MsgArea*** | task output |
| **LazyUrl** | ***@markup.link*** | url |
| **LazyValue** | ***@string*** | value of a property |
| **LazyWarning** | ***DiagnosticWarn*** | task errors |

# 🚀 Usage

## ▶️ Startup Sequence

**lazy.nvim** does **NOT** use Neovim packages and even disables plugin loading
completely (`vim.go.loadplugins = false`). It takes over the complete
startup sequence for more flexibility and better performance.

In practice this means that step 10 of [Neovim Initialization](https://neovim.io/doc/user/starting.html#_initialization) is done by Lazy:

1. All the plugins' `init()` functions are executed
2. All plugins with `lazy=false` are loaded. This includes sourcing `/plugin` and `/ftdetect` files. (`/after` will not be sourced yet)
3. All files from `/plugin` and `/ftdetect` directories in your rtp are sourced (excluding `/after`)
4. All `/after/plugin` files are sourced (this includes `/after` from plugins)

Files from runtime directories are always sourced in alphabetical order.

## 🚀 Commands

Plugins are managed with the `:Lazy` command.
Open the help with `<?>` to see all the key mappings.

You can press `<CR>` on a plugin to show its details. Most properties
can be hovered with `<K>` to open links, help files, readmes,
git commits and git issues.

Lazy can automatically check for updates in the background. This feature
can be enabled with `config.checker.enabled = true`.

Any operation can be started from the UI, with a sub command or an API function:

| Command | Lua | Description |
| --- | --- | --- |
| `:Lazy build {plugins}` | `require("lazy").build(opts)` | Rebuild a plugin |
| `:Lazy check [plugins]` | `require("lazy").check(opts?)` | Check for updates and show the log (git fetch) |
| `:Lazy clean [plugins]` | `require("lazy").clean(opts?)` | Clean plugins that are no longer needed |
| `:Lazy clear` | `require("lazy").clear()` | Clear finished tasks |
| `:Lazy debug` | `require("lazy").debug()` | Show debug information |
| `:Lazy health` | `require("lazy").health()` | Run `:checkhealth lazy` |
| `:Lazy help` | `require("lazy").help()` | Toggle this help page |
| `:Lazy home` | `require("lazy").home()` | Go back to plugin list |
| `:Lazy install [plugins]` | `require("lazy").install(opts?)` | Install missing plugins |
| `:Lazy load {plugins}` | `require("lazy").load(opts)` | Load a plugin that has not been loaded yet. Similar to `:packadd`. Like `:Lazy load foo.nvim`. Use `:Lazy! load` to skip `cond` checks. |
| `:Lazy log [plugins]` | `require("lazy").log(opts?)` | Show recent updates |
| `:Lazy profile` | `require("lazy").profile()` | Show detailed profiling |
| `:Lazy reload {plugins}` | `require("lazy").reload(opts)` | Reload a plugin (experimental!!) |
| `:Lazy restore [plugins]` | `require("lazy").restore(opts?)` | Updates all plugins to the state in the lockfile. For a single plugin: restore it to the state in the lockfile or to a given commit under the cursor |
| `:Lazy sync [plugins]` | `require("lazy").sync(opts?)` | Run install, clean and update |
| `:Lazy update [plugins]` | `require("lazy").update(opts?)` | Update plugins. This will also update the lockfile |

Any command can have a **bang** to make the command wait till it finished. For example,
if you want to sync lazy from the cmdline, you can use:

```shell
nvim --headless "+Lazy! sync" +qa
```

`opts` is a table with the following key-values:

- **wait**: when true, then the call will wait till the operation completed
- **show**: when false, the UI will not be shown
- **plugins**: a list of plugin names to run the operation on
- **concurrency**: limit the `number` of concurrently running tasks

Stats API (`require("lazy").stats()`):

```lua
{
  -- startuptime in milliseconds till UIEnter
  startuptime = 0,
  -- when true, startuptime is the accurate cputime for the Neovim process. (Linux & macOS)
  -- this is more accurate than `nvim --startuptime`, and as such will be slightly higher
  -- when false, startuptime is calculated based on a delta with a timestamp when lazy started.
  real_cputime = false,
  count = 0, -- total number of plugins
  loaded = 0, -- number of loaded plugins
  ---@type table<string, number>
  times = {},
}
```

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

## 📆 User Events

The following user events will be triggered:

- **LazyDone**: when lazy has finished starting up and loaded your config
- **LazySync**: after running sync
- **LazyInstall**: after an install
- **LazyUpdate**: after an update
- **LazyClean**: after a clean
- **LazyCheck**: after checking for updates
- **LazyLog**: after running log
- **LazyLoad**: after loading a plugin. The `data` attribute will contain the plugin name.
- **LazySyncPre**: before running sync
- **LazyInstallPre**: before an install
- **LazyUpdatePre**: before an update
- **LazyCleanPre**: before a clean
- **LazyCheckPre**: before checking for updates
- **LazyLogPre**: before running log
- **LazyReload**: triggered by change detection after reloading plugin specs
- **VeryLazy**: triggered after `LazyDone` and processing `VimEnter` auto commands
- **LazyVimStarted**: triggered after `UIEnter` when `require("lazy").stats().startuptime` has been calculated.
  Useful to update the startuptime on your dashboard.

## ❌ Uninstalling

To uninstall **lazy.nvim**, you need to remove the following files and directories:

- **data**: `~/.local/share/nvim/lazy`
- **state**: `~/.local/state/nvim/lazy`
- **lockfile**: `~/.config/nvim/lazy-lock.json`

> Paths can differ if you changed `XDG` environment variables.

## 🔒 Lockfile

After every **update**, the local lockfile (`lazy-lock.json`) is updated with the installed revisions.
It is recommended to have this file under version control.

If you use your Neovim config on multiple machines, using the lockfile, you can
ensure that the same version of every plugin is installed.

If you are on another machine, you can do `:Lazy restore`, to update all your plugins to
the version from the lockfile.

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
- `after` is **_not needed_** for most use-cases. Use `dependencies` otherwise.
- `wants` is **_not needed_** for most use-cases. Use `dependencies` otherwise.
- `config` don't support string type, use `fun(LazyPlugin)` instead.
- `module` is auto-loaded. No need to specify
- `keys` spec is [different](#%EF%B8%8F-lazy-key-mappings)
- `rtp` can be accomplished with:

```lua
config = function(plugin)
    vim.opt.rtp:append(plugin.dir .. "/custom-rtp")
end
```

With packer `wants`, `requires` and `after` can be used to manage dependencies.
With lazy, this isn't needed for most of the Lua dependencies. They can be installed just like normal plugins
(even with `lazy=true`) and will be loaded when other plugins need them.
The `dependencies` key can be used to group those required plugins with the one that requires them.
The plugins which are added as `dependencies` will always be lazy-loaded and loaded when the plugin is loaded.

### [paq-nvim](https://github.com/savq/paq-nvim)

- `as` ➡️ `name`
- `opt` ➡️ `lazy`
- `run` ➡️ `build`

## ⚡ Profiling & Debug

Great care has been taken to make the startup code (`lazy.core`) as efficient as possible.
During startup, all Lua files used before `VimEnter` or `BufReadPre` are byte-compiled and cached,
similar to what [impatient.nvim](https://github.com/lewis6991/impatient.nvim) does.

My config for example loads in about `11ms` with `93` plugins. I do a lot of lazy-loading though :)

**lazy.nvim** comes with an advanced profiler `:Lazy profile` to help you improve performance.
The profiling view shows you why and how long it took to load your plugins.

![image](https://user-images.githubusercontent.com/292349/208301766-5c400561-83c3-4811-9667-1ec4bb3c43b8.png)

### 🐛 Debug

See an overview of active lazy-loading handlers and what's in the module cache.

![image](https://user-images.githubusercontent.com/292349/208301790-7eedbfa5-d202-4e70-852e-de68aa47233b.png)

## 📂 Structuring Your Plugins

Some users may want to split their plugin specs in multiple files.
Instead of passing a spec table to `setup()`, you can use a Lua module.
The specs from the **module** and any top-level **sub-modules** will be merged together in the final spec,
so it is not needed to add `require` calls in your main plugin file to the other files.

The benefits of using this approach:

- Simple to **add** new plugin specs. Just create a new file in your plugins module.
- Allows for **caching** of all your plugin specs. This becomes important if you have a lot of smaller plugin specs.
- Spec changes will automatically be **reloaded** when they're updated, so the `:Lazy` UI is always up to date.

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

- Any lua file in `~/.config/nvim/lua/plugins/*.lua` will be automatically merged in the main plugin spec

For a real-life example, you can check [LazyVim](https://github.com/LazyVim/LazyVim) and more specifically:

- [lazyvim.plugins](https://github.com/LazyVim/LazyVim/tree/main/lua/lazyvim/plugins) contains all the plugin specs that will be loaded

#### ↩️ Importing Specs, `config` & `opts`

As part of a spec, you can add `import` statements to import additional plugin modules.
Both of the `setup()` calls are equivalent:

```lua
require("lazy").setup("plugins")

-- Same as:
require("lazy").setup({{import = "plugins"}})
```

To import multiple modules from a plugin, add additional specs for each import.
For example, to import LazyVim core plugins and an optional plugin:

```lua
require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "lazyvim.plugins.extras.coding.copilot" },
  }
})
```

When you import specs, you can override them by simply adding a spec for the same plugin to your local
specs, adding any keys you want to override / merge.

`opts`, `dependencies`, `cmd`, `event`, `ft` and `keys` are always merged with the parent spec.
Any other property will override the property from the parent spec.

# 🔥 Developers

To make it easier for users to install your plugin, you can include a [package spec](/packages) in your repo.

## Best Practices

- If your plugin needs `setup()`, then create a simple `lazy.lua` file like this:

  ```lua
    return { "me/my-plugin", opts = {} }
  ```

- Plugins that are pure lua libraries should be lazy-loaded with `lazy = true`.

  ```lua
  { "nvim-lua/plenary.nvim", lazy = true }
  ```

- Always use `opts` instead of `config` when possible. `config` is almost never needed.

  :::tip[GOOD]

  ```lua
  { "folke/todo-comments.nvim", opts = {} },
  ```

  :::

  :::danger[BAD]

  ```lua
  {
    "folke/todo-comments.nvim",
    config = function()
      require("todo-comments").setup({})
    end,
  },
  ```

  :::

- Only use `dependencies` if a plugin needs the dep to be installed **AND** loaded.
  Lua plugins/libraries are automatically loaded when they are `require()`d,
  so they don't need to be in `dependencies`.

  :::tip[GOOD]

  ```lua
  { "folke/todo-comments.nvim", opts = {} },
  { "nvim-lua/plenary.nvim", lazy = true },
  ```

  :::

  :::danger[BAD]

  ```lua
  {
    "folke/todo-comments.nvim",
    opts = {},
    -- This will always load plenary as soon as todo-comments loads,
    -- even when todo-comments doesn't use it.
    dependencies = { "nvim-lua/plenary.nvim", lazy = true },
  },
  ```

  :::

- Inside a `build` function or `*.lua` build file, use `coroutine.yield(msg:string|LazyMsg)` to show progress.

- Don't change the `cwd` in your build function, since builds run in parallel and changing the `cwd` will affect other builds.

## Building

The spec **build** property can be one of the following:

- `fun(plugin: LazyPlugin)`: a function that builds the plugin.
- `*.lua`: a Lua file that builds the plugin (like `build.lua`)
- `":Command"`: a Neovim command
- `"rockspec"`: this will run `luarocks make` in the plugin's directory
  This is automatically set by the `rockspec` [package](/packages) source.
- any other **string** will be run as a shell command
- a `list` of any of the above to run multiple build steps
- if no `build` is specified, but a `build.lua` file exists, that will be used instead.

Build functions and `*.lua` files run asynchronously in a coroutine.
Use `coroutine.yield(msg:string|LazyMsg)` to show progress.

Yielding will also schedule the next `coroutine.resume()` to run in the next tick, so you can do long-running tasks without blocking Neovim.

```lua
---@class LazyMsg
---@field msg string
---@field level? number vim.log.levels.XXX
```

Use `vim.log.levels.TRACE` to only show the message as a **status** message for the task.

:::tip

If you need to know the directory of your build lua file, you can use:

```lua
local dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
```

:::

## Minit (Minimal Init)

**lazy.nvim** comes with some built-in functionality to help you create a minimal init for your plugin.

I mainly use this for testing and for users to create a `repro.lua`.

When running in **headless** mode, **lazy.nvim** will log any messages to the terminal.
See `opts.headless` for more info.

**minit** will install/load all your specs and will always run an update as well.

### Bootstrap

```lua
-- setting this env will override all XDG paths
vim.env.LAZY_STDPATH = ".tests"
-- this will install lazy in your stdpath
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()
```

### Testing with Busted

This will add `"lunarmodules/busted"`, configure `hererocks` and run `busted`.

Below is an example of how I use **minit** to run tests with [busted](https://olivinelabs.com/busted/)
in **LazyVim**.

```lua
#!/usr/bin/env -S nvim -l

vim.env.LAZY_STDPATH = ".tests"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

-- Setup lazy.nvim
require("lazy.minit").busted({
  spec = {
    "LazyVim/starter",
    "williamboman/mason-lspconfig.nvim",
    "williamboman/mason.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
})
```

To use this, you can run:

```sh
nvim -l ./tests/busted.lua tests
```

If you want to inspect the test environment, run:

```sh
nvim -u ./tests/busted.lua
```

### `repro.lua`

```lua
vim.env.LAZY_STDPATH = ".repro"
load(vim.fn.system("curl -s https://raw.githubusercontent.com/folke/lazy.nvim/main/bootstrap.lua"))()

require("lazy.minit").repro({
  spec = {
    "stevearc/conform.nvim",
    "nvim-neotest/nvim-nio",
  },
})

-- do anything else you need to do to reproduce the issue
```

Then run it with:

```sh
nvim -u repro.lua
```