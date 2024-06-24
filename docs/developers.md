---
sidebar_position: 7
---
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

- Inside a `build` function or `*.lua` build file, use `coroutine.yield(status_msg)` to show progress.

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
Use `coroutine.yield(status_msg)` to show progress.
Yielding will also schedule the next `coroutine.resume()` to run in the next tick, so you can do long-running tasks without blocking Neovim.

:::tip

If you need to know the directory of your build lua file, you can use:

```lua
local dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
```

:::

