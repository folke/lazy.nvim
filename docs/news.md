---
sidebar_position: 10
---
# 📰 What's new?

## 11.x

- **New Website**: There's a whole new website with a fresh look and improved documentation.
  Check it out at [lazy.nvim](https://lazy.folke.io/).
  The GitHub `README.md` has been updated to point to the new website.
  The `vimdoc` contains all the information that is available on the website.

- **Spec Resolution & Merging**: the code that resolves a final spec from a plugin's fragments has been rewritten.
  This should be a tiny bit faster, but more importantly, fixes some issues and is easier to maintain.

- `rocks`: specs can now specify a list of rocks ([luarocks](https://luarocks.org/)) that should be installed.

- [Packages](https://lazy.folke.io/packages) can now specify their dependencies and configuration using one of:
  - **Lazy**: `lazy.lua` file
  - **Rockspec**: [luarocks](https://luarocks.org/) `*-scm-1.rockspec` [file](https://github.com/luarocks/luarocks/wiki/Rockspec-format)
  - **Packspec**: `pkg.json` (experimental, since the [format](https://github.com/neovim/packspec/issues/41) is not quite there yet)

