---
sidebar_position: 2
---
# 🔥 Installation

You can add the following Lua code to your `init.lua` to bootstrap **lazy.nvim**:

<!-- bootstrap:start -->

```lua title="lua/config/lazy.lua"
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)
```

<!-- bootstrap:end -->

Next step is to add **lazy.nvim** below the code added in the prior step in `init.lua`:

```lua
require("lazy").setup(plugins, opts)
```

- **plugins**: this should be a `table` or a `string`
  - `table`: a list with your [Plugin Spec](#-plugin-spec)
  - `string`: a Lua module name that contains your [Plugin Spec](#-plugin-spec). See [Structuring Your Plugins](#-structuring-your-plugins)
- **opts**: see [Configuration](#%EF%B8%8F-configuration) **_(optional)_**

```lua
-- Example using a list of specs with the default options
vim.g.mapleader = " " -- Make sure to set `mapleader` before lazy so your mappings are correct
vim.g.maplocalleader = "\\" -- Same for `maplocalleader`

require("lazy").setup({
  "folke/which-key.nvim",
  { "folke/neoconf.nvim", cmd = "Neoconf" },
  "folke/neodev.nvim",
})
```

ℹ️ It is recommended to run `:checkhealth lazy` after installation.

