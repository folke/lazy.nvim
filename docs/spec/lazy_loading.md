# Lazy Loading

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

## 🌈 Colorschemes

Colorscheme plugins can be configured with `lazy=true`. The plugin will automagically load
when doing `colorscheme foobar`.

:::warning

since **start** plugins can possibly change existing highlight groups,
it's important to make sure that your main **colorscheme** is loaded first.
To ensure this you can use the `priority=1000` field. **_(see the [examples](./examples.md))_**

:::

## ⌨️ Lazy Key Mappings

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
    config = function()
      require("neo-tree").setup()
    end,
}
```
