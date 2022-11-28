# lazy.nvim

## ✨ Features

- Partial clones instead of shallow clones
- Async
- No need for compile
- Fast
- Correct sequencing of dependencies (deps should always be opt. Maybe make everything opt?)
- [ ] Import specs from Packer
- Config in multiple files
- Patterns for local packages
- [ ] lockfile
- [ ] package.lua
- [ ] package-lock.lua
- [ ] tag/version support `git tag --sort version:refname`
- [ ] auto-loading on completion for lazy-loaded commands
- [ ] semver https://devhints.io/semver
      https://semver.npmjs.com/

## ✅ TODO

- [ ] show time taken for op in view
- [ ] package meta index (package.lua cache for all packages)
- [ ] migrate from Packer
- [ ] auto lazy-loading of lua modules
- [ ] use uv file watcher to check for config changes
- [x] clear errors
- [ ] add support for versions `git tag --sort v:refname`
- [ ] rename requires to deps
- [ ] move tasks etc to Plugin.state
  - loaded
  - installed
  - updated
  - changed: just installed or updated (dirty)
  - is_local
    https://github.blog/2020-12-21-get-up-to-speed-with-partial-clone-and-shallow-clone/

## 🖥️ Git Operations

1. **install**:

   - run `git clone` with given `branch`,`--single-branch`, `filter=blob:none`
     and `--no-checkout`
   - run `git checkout` with correct `branch`, `tag` or `commit`

2. **update**:

   - if branch is missing `git remote set-branches --add origin MISSING_BRANCH`
     - `git switch MISSING_BRANCH`
   - run `git fetch`
   - run `git checkout` with correct `branch`, `tag` or `commit`
