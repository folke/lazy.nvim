# 📦 Migration Guide

## [packer.nvim](https://github.com/wbthomason/packer.nvim)

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

## [paq-nvim](https://github.com/savq/paq-nvim)

- `as` ➡️ `name`
- `opt` ➡️ `lazy`
- `run` ➡️ `build`
