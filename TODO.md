# ✅ TODO

- [x] progress bar?
- [x] options when opening file
- [x] lazy notify? not ideal when installing missing stuff
- [x] topmods?

- [ ] better merging options?
- [ ] especially what to do with merging of handlers?
- [ ] overwriting keymaps probably doesn't work
- [ ] disabled deps?

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
- [x] show spec errors in health
- [x] fix plugin details
- [ ] show disabled plugins (strikethrough?)
- [ ] log file
- [x] git tests
- [x] Import specs from other plugin managers
- [ ] [packspec](https://github.com/nvim-lua/nvim-package-specification)

  - [ ] add support to specify `engines`, `os` and `cpu` like in `package.json`
  - [ ] semver merging. Should check if two or more semver ranges are compatible and calculate the union range
    - default semver merging strategy: if no version matches all, then use the highest version?
  - [ ] package meta index (package.lua cache for all packages)

- [x] document highlight groups
- [x] document user events
- [x] document API, like lazy.plugins()
- [x] icons

- [x] check in cache if rtp files match
- [x] I think the installation section, specifically the loading part, could use an
      extra sentence or two. I was confused on what `config.plugins` was initially.
      Maybe a quick, "for example, if you have a lua file
      `~/.config/nvim/lua/config/plugins.lua` that returns a table" or something it'd
      remove most question marks I think.
- [x] When auto-installing the plugins the cursor isn't focused on the floating
      window, but on the non-floating window in the background.
- [x] Doing `:Lazy clean` doesn't show which plugins were removed.
- [x] Shouldn't the "Versioning" section be in the "Lockfile" chapter?
- [x] Why are personal dotfiles used as examples? Dotfiles change all the time,
      there's no guarantee this will be relevant or even exist in two years.
- [x] What's the difference between lazy-loading and verylazy-loading?
- [x] Most emojis in "Configuration" aren't shown for me.
- [x] add section on how to uninstall
- [x] add `:Packadd` command or something similar
- [x] headless install
- [x] better keys handling
