---
sidebar_position: 4
---
# 📦 Packages

**lazy.nvim** supports three ways for plugins to define their dependencies and configuration.

- **Lazy**: `.lazy.lua` file
- **Rockspec**: [luarocks](https://luarocks.org/) `*-scm-1.rockspec` [file](https://github.com/luarocks/luarocks/wiki/Rockspec-format)
- **Packspec**: `pkg.json` (experimental, since the [format](https://github.com/neovim/packspec/issues/41) is not quite there yet)

You can enable/disable package sources with [`config.pkg.sources`](/configuration).
The order of sources is important, as the first source that finds a package will be used.

:::info

Package specs are always loaded in the scope of the plugin (using [specs](/spec#advanced)),
so that when the plugin is disabled, none of the specs are loaded.

:::

## Lazy

Using a `.lazy.lua` file is the recommended way to define your plugin dependencies and configuration.
Syntax is the same as any plugin spec.

## Rockspec

When a plugin contains a `*-scm-1.rockspec` file, **lazy.nvim** will automatically load its [`rocks`](/spec#setup) dependencies.

## Packspec

Supports the [pkg.json](https://github.com/nvim-lua/nvim-package-specification/issues/41) format,
with a lazy extension in `lazy`.
`lazy` can contain any valid lazy spec fields. They will be added to the plugin's spec.

