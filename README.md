# lazy.nvim

## ✨ Features

- [x] Partial clones instead of shallow clones
- [x] waits till missing deps are installed (bootstrap Neovim and start using it right away)
- [x] Async
- [x] No need for compile
- [x] Fast
- [x] Correct sequencing of dependencies (deps should always be opt. Maybe make everything opt?)
- [x] Config in multiple files
- [x] Patterns for local packages
- [x] Profiling
- [x] lockfile
- [x] upvalues in `config` & `init`
- [x] check for updates
- [x] lazy-lock.lua
- [x] tag/version support `git tag --sort version:refname`
- [x] auto-loading on completion for lazy-loaded commands
- [x] bootstrap code
- [x] semver https://devhints.io/semver
      https://semver.npmjs.com/

## ✅ TODO

- [ ] health checks: check merge conflicts async
  - [ ] unsupported props or props from other managers
- [x] rename `run` to `build`
- [ ] allow setting up plugins through config
- [x] task timeout
- [ ] log file
- [ ] deal with re-sourcing init.lua. Check a global?
- [x] incorrect when switching TN from opt to start
- [ ] git tests
- [x] max concurrency
- [x] ui border
- [ ] make sure we can reload specs while keeping state
- [ ] show disabled plugins (strikethrough?)
- [ ] Import specs from Packer
- [ ] use uv file watcher (or stat) to check for config changes
- [ ] [packspec](https://github.com/nvim-lua/nvim-package-specification)
  - [ ] add support to specify `engines`, `os` and `cpu` like in `package.json`
  - [ ] semver merging. Should check if two or more semver ranges are compatible and calculate the union range
    - default semver merging strategy: if no version matches all, then use highest version?
- [x] support for Plugin.lock
- [x] defaults for git log
- [x] view keybindings for update/clean/...
- [x] add profiler to view
- [x] add buttons for actions
- [x] show time taken for op in view
- [ ] package meta index (package.lua cache for all packages)
- [ ] auto lazy-loading of lua modules
- [x] clear errors
- [x] add support for versions `git tag --sort v:refname`
- [x] rename requires to dependencies
- [x] move tasks etc to Plugin.state
- [x] handlers imply opt
- [x] dependencies imply opt for deps
- [x] fix local plugin spec
- [ ] investigate all opt=true. Simplifies logic (easily switch between opt/start afterwards)

## 📦 Differences with Packer

- **Plugin Spec**:

  - `setup` => `init`
  - `requires` => `dependencies`
  - `as` => `name`

## 📦 Other Neovim Plugin Managers in Lua

- [packer.nvim](https://github.com/wbthomason/packer.nvim)
- [paq-nvim](https://github.com/savq/paq-nvim)
- [neopm](https://github.com/ii14/neopm)
- [dep](https://github.com/chiyadev/dep)
- [optpack.nvim](https://github.com/notomo/optpack.nvim)
