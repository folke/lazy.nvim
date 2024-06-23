# 📂 Structuring Your Plugins

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

### ↩️ Importing Specs, `config` & `opts`

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
