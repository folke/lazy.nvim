# lazy.nvim

## ✨ Features

- [x] Partial clones instead of shallow clones
- [x] waits till missing deps are installed (bootstrap Neovim and start using it right away)
- [x] Async
- [x] No need for compile
- [x] Fast
- [x] Correct sequencing of dependencies (deps should always be opt. Maybe make everything opt?)
- [ ] Import specs from Packer
- [x] Config in multiple files
- [x] Patterns for local packages
- [x] Profiling
- [x] lockfile
- [x] upvalues in `config` & `init`
- [x] check for updates
- [ ] package.lua
- [ ] package-lock.lua
- [x] tag/version support `git tag --sort version:refname`
- [x] auto-loading on completion for lazy-loaded commands
- [x] semver https://devhints.io/semver
      https://semver.npmjs.com/

## ✅ TODO

- [ ] health checks: check merge conflicts async
- [ ] defaults for git log
- [x] view keybindings for update/clean/...
- [x] add profiler to view
- [x] add buttons for actions
- [x] show time taken for op in view
- [ ] package meta index (package.lua cache for all packages)
- [ ] migrate from Packer
- [ ] auto lazy-loading of lua modules
- [ ] use uv file watcher to check for config changes
- [x] clear errors
- [x] add support for versions `git tag --sort v:refname`
- [ ] rename requires to deps
- [x] move tasks etc to Plugin.state
- [ ] allow setting up plugins through config
