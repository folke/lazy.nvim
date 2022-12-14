# 💤 lazy.nvim

Modern plugin manager for Neovim

![image](https://user-images.githubusercontent.com/292349/207705153-077e183e-ae5f-4cbe-b1d8-07b7bf86026e.png)

## ✨ Features

- 📦 Manage all your Neovim plugins with a fancy UI
- 🚀 Fast startup: Automatically caches and compiles byte code of all lua modules needed during startup
- 💾 Partial clones instead of shallow clones
- 🔌 Auto lazy-loading of lua modules
- 📆 Lazy-loading on events, commands, filetypes and key mappings
- ⏳ Automatically installs missing plugins before starting up so you can start using Neovim right away
- 💪 Async execution for improved performance
- 🛠️ No need to manually compile plugins
- 🧪 Correct sequencing of dependencies
- 📁 Configurable in multiple files
- 💻 Dev option and patterns for using local plugin
- 📊 Profiling tools to optimize performance
- 🔒 Lockfile `lazy-lock.json` to keep track of installed plugin versions
- 🔎 Automatically check for updates
- 📋 Commit, branch, tag, version, and full [Semver](https://devhints.io/semver) support
- 📈 Statusline component to see the number of pending updates

## ⚡️ Requirements

- Neovim >= **0.8.0**

## Profiler

The profiling view shows you why and how long it took to load your plugins.

![image](https://user-images.githubusercontent.com/292349/207703263-3b38ca45-9779-482b-b684-4f8c3b3e76d0.png)

## Debug

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
