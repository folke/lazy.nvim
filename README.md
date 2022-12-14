# 💤 lazy.nvim

Modern plugin manager for Neovim

![image](https://user-images.githubusercontent.com/292349/207702945-6f1e7c89-9076-430b-b9e1-0bae8864a772.png)

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

## ✅ TODO

- [x] fancy UI to manage all your Neovim plugins
- [x] auto lazy-loading of lua modules
- [x] lazy-loading on events, commands, filetypes and key mappings
- [x] Partial clones instead of shallow clones
- [x] waits till missing deps are installed (bootstrap Neovim and start using it right away)
- [x] Async
- [x] No need to manually compile
- [x] Fast. Automatically caches and compiles byte code of all lua modules needed during startup
- [x] Correct sequencing of dependencies (deps should always be opt. Maybe make everything opt?)
- [x] Config in multiple files
- [x] dev option and patterns for local packages
- [x] Profiling
- [x] lockfile `lazy-lock.json`
- [x] upvalues in `config` & `init`
- [x] automatically check for updates
- [x] commit, branch, tag, version and full semver support
- [x] statusline component to see number of pending updates

- [x] semver https://devhints.io/semver
- [x] auto-loading on completion for lazy-loaded commands
- [x] bootstrap code
- [x] Background update checker
- [x] health checks: check merge conflicts async
  - [x] unsupported props or props from other managers
  - [x] other packages still in site?
  - [x] other package manager artifacts still present? compiled etc
- [x] status page showing running handlers and cache stats
- [x] temp colorscheme used during startup when installing missing plugins
- [x] automatically reloads when config changes are detected
- [x] handlers imply opt
- [x] dependencies imply opt for deps
- [ ] show spec errors in health
- [ ] fix plugin details
- [ ] show disabled plugins (strikethrough?)
- [ ] log file
- [ ] git tests
- [ ] Import specs from other plugin managers
- [ ] [packspec](https://github.com/nvim-lua/nvim-package-specification)
  - [ ] add support to specify `engines`, `os` and `cpu` like in `package.json`
  - [ ] semver merging. Should check if two or more semver ranges are compatible and calculate the union range
    - default semver merging strategy: if no version matches all, then use highest version?
  - [ ] package meta index (package.lua cache for all packages)
  
## Profiler

![image](https://user-images.githubusercontent.com/292349/207703263-3b38ca45-9779-482b-b684-4f8c3b3e76d0.png)


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
