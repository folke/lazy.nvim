# Changelog

## [5.0.0](https://github.com/folke/lazy.nvim/compare/v4.2.0...v5.0.0) (2022-12-20)


### ⚠ BREAKING CHANGES

* removed the LazyUpdate etc commands. sub-commands only from now on

### Features

* added `:Lazy load foobar.nvim` to load a plugin ([2dd6230](https://github.com/folke/lazy.nvim/commit/2dd623001891ad98845523c92e8fcc6043993019))
* added `module=false` to skip auto-loading of plugins on `require` ([1efa710](https://github.com/folke/lazy.nvim/commit/1efa710210ded9677dce8ceb523e08e133c10e1f))
* added completion for all lazy commands ([5ed9855](https://github.com/folke/lazy.nvim/commit/5ed9855d1c31440957eb54b2741a992ed51cc969))
* added support for Windows ([bb1c2f4](https://github.com/folke/lazy.nvim/commit/bb1c2f4c3ef83f79263d7832dd3a91991fcf62d7))
* removed the LazyUpdate etc commands. sub-commands only from now on ([d4aee27](https://github.com/folke/lazy.nvim/commit/d4aee2715fa22ab29422320d817236e927260335))
* utility method to normalize a path ([198963f](https://github.com/folke/lazy.nvim/commit/198963fdabdb24e530808542090c5de3f28ec808))


### Bug Fixes

* **cache:** do a fast check to see if a cached modpath is still valid. find it again otherwise ([32f2b71](https://github.com/folke/lazy.nvim/commit/32f2b71ff884e88358790348d5620ed494ef80b6))
* **cache:** normalize paths ([62c1542](https://github.com/folke/lazy.nvim/commit/62c1542141926aeeb79435cb8a8593e47cc89e43))
* check for installed plugins with plain find ([a189883](https://github.com/folke/lazy.nvim/commit/a18988372faecbd097946dbef6286dd82dca744d))
* **ui:** focus Lazy window when auto-installing plugins in `VimEnter` ([1fe43f3](https://github.com/folke/lazy.nvim/commit/1fe43f3e294cf994a52d25e16dc630e66db2970c))
* **util:** fixed double slashes ([af87108](https://github.com/folke/lazy.nvim/commit/af87108605b624608b46e0f3365cc9a2539c5ec8))


### Performance Improvements

* **cache:** cache loadfile and no find modpaths without package.loaders ([faac2dd](https://github.com/folke/lazy.nvim/commit/faac2dd11c932e71a0cea9bc933f8bbe1e1d2312))
* lazy-load the commands available on the `lazy` module ([b89e6bf](https://github.com/folke/lazy.nvim/commit/b89e6bffd258e4dd367992c306b588e9b24b9a76))

## [4.2.0](https://github.com/folke/lazy.nvim/compare/v4.1.0...v4.2.0) (2022-12-18)


### Features

* check if ffi is available and error if not ([c0d3617](https://github.com/folke/lazy.nvim/commit/c0d3617e0b45b68abc522778837ff8a472273c15))
* expose all commands on main lazy module ([f25f942](https://github.com/folke/lazy.nvim/commit/f25f942eb76f485d09f770dd5ea4c4ca3bef4e0b))
* **loader:** added error handler to sourcing of runtime files ([eeb06a5](https://github.com/folke/lazy.nvim/commit/eeb06a5a509c27b7f0877b513f2278f27cc98f67))
* never source `packer_compiled.lua` ([a46c0c0](https://github.com/folke/lazy.nvim/commit/a46c0c04f13ef4bb10c42004a72a48356f8cfe93))
* **ui:** added dir to props ([9736671](https://github.com/folke/lazy.nvim/commit/97366711bedc7bfc2e9a425e8dfa6f9891e9c865))
* **ui:** added help for &lt;CR&gt; on a plugin ([c87673c](https://github.com/folke/lazy.nvim/commit/c87673c4b97578d7dd6f14e421486cfa6e008b91))
* **ui:** made it look a little less like a Mason rip-off :) ([9026a0e](https://github.com/folke/lazy.nvim/commit/9026a0e25d4e3ebfe2cac7d7a724cb8211fac4f1))
* **ui:** make home bold ([0b4a04d](https://github.com/folke/lazy.nvim/commit/0b4a04de7d264b5890210f92eef0e6521bf8d0c9))


### Bug Fixes

* **loader:** runtime files are now sourced alphabetically per directory ([5c0c381](https://github.com/folke/lazy.nvim/commit/5c0c381b56f78622df47e2057210232ed0a3275e))
* set correct dir for lazy plugin ([23984dd](https://github.com/folke/lazy.nvim/commit/23984dd1f300e09cbc1bc9a80aae3bea32a5bbcc))
* **ui:** always clear complete tasks with the same name when starting a new task ([85e3752](https://github.com/folke/lazy.nvim/commit/85e375223f21e35fd5f779cad05be0397557e72a))
* **ui:** show first tag for each help doc in details ([6f728e6](https://github.com/folke/lazy.nvim/commit/6f728e698d5e19de36dd861f6699b6b4560e5f42))
* **ui:** split window before opening a file from the Lazy ui, otherwise it'll get closed immediately ([f18efa1](https://github.com/folke/lazy.nvim/commit/f18efa1da1b1274466444a477574ac2b6a2c24b3))

## [4.1.0](https://github.com/folke/lazy.nvim/compare/v4.0.0...v4.1.0) (2022-12-16)


### Features

* **docs:** added toc generator ([f4720ee](https://github.com/folke/lazy.nvim/commit/f4720ee9f745c0b77366f1e5e6ea7fc7bfaf8010))
* lua code generator for the README.md ([80a7839](https://github.com/folke/lazy.nvim/commit/80a7839eec62560e9160663cee4ea4c9e67196fc))
* README.md files are now automagically added to help. By default only when no doc/ exists ([70ca110](https://github.com/folke/lazy.nvim/commit/70ca110ca19c305dfe2790de5a82f5e6789a73ee))
* utility methods to read/write files ([27178b5](https://github.com/folke/lazy.nvim/commit/27178b5e6759f6429602acfeb674834e0dad1f13))


### Bug Fixes

* `Plugin.init` implies lazy-loading ([ccdf65b](https://github.com/folke/lazy.nvim/commit/ccdf65b5b8974438cb60c10ec00c7302c339f9da))
* add lazy.nvim with dev=false to prevent using the dev version for myself ([b8fa6f9](https://github.com/folke/lazy.nvim/commit/b8fa6f960f9bff5e17a7731a204cad21d564ef34))
* bootstrap code now uses git url instead of https for beta testers + fixed rtp path ([17d1653](https://github.com/folke/lazy.nvim/commit/17d1653b4a39b80e0d59e3e4877cf23cdd9b6756))
* use initial rtp for rtp plugin after files and use loaded plugins for their after files ([7134417](https://github.com/folke/lazy.nvim/commit/7134417e89319514c9bd9a8913012a396095f48d))


### Performance Improvements

* prevent string.match to find plugin name from a modpath ([f23a6ee](https://github.com/folke/lazy.nvim/commit/f23a6eef8ca3e8416167266cafd037a5e27a7cc6))
* when reloading plugin specs always use cache ([060cf23](https://github.com/folke/lazy.nvim/commit/060cf23aca3826c213ad26ff1860815b03064269))

## [4.0.0](https://github.com/folke/lazy.nvim/compare/v3.0.0...v4.0.0) (2022-12-14)


### ⚠ BREAKING CHANGES

* lazy now handles the full startup sequence (`vim.go.loadplugins=false`)

### Features

* added checks for Neovim version ([72f64ce](https://github.com/folke/lazy.nvim/commit/72f64ce1f7a3bbcbc500a7e0f8d7950376ec6a12))
* getter for plugins ([8de617c](https://github.com/folke/lazy.nvim/commit/8de617c01b572965d8a48362597fce01dc3ebcc7))
* lazy now handles the full startup sequence (`vim.go.loadplugins=false`) ([ec2f432](https://github.com/folke/lazy.nvim/commit/ec2f432a84bead4aaaf684b4eb2d88e41592703e))
* **ui:** show `updates available` diagnostic when an update is available ([ad0b4ca](https://github.com/folke/lazy.nvim/commit/ad0b4caa648fe84eb1dff5e55d3f02d293b33ad1))


### Bug Fixes

* destroy the cache when VIMRUNTIME has changed ([5128d89](https://github.com/folke/lazy.nvim/commit/5128d896c759c0599b6da5f5ba2cee102d864cad))
* updated the bootstrap code ([1ee4e8b](https://github.com/folke/lazy.nvim/commit/1ee4e8b7197ff23383a6a3306cdd15f20be04b72))

## [3.0.0](https://github.com/folke/lazy.nvim/compare/v2.2.0...v3.0.0) (2022-12-13)


### ⚠ BREAKING CHANGES

* local plugins now always need to set `Plugin.dir`

### Features

* added health checks ([dc2dcd2](https://github.com/folke/lazy.nvim/commit/dc2dcd2d5a8c256497235428e129907e99e0ae58))
* **api:** return runner from manage operations ([71e4b92](https://github.com/folke/lazy.nvim/commit/71e4b92fd6fbb807ef82ebc9586cfe2a233234b4))
* better way of dealing with lazy loaded completions (thanks to [@lewis6991](https://github.com/lewis6991)) ([f24c055](https://github.com/folke/lazy.nvim/commit/f24c055fe9ebc810dfb35328dd312d4cd9038db1))
* **checker:** only report an update once and do a fast update check after each manage operation ([2a7466a](https://github.com/folke/lazy.nvim/commit/2a7466abadb7987e81009cdd06042fb2d2b59366))
* local plugins now always need to set `Plugin.dir` ([0625493](https://github.com/folke/lazy.nvim/commit/0625493aadf025476c62841fc3d36bf836f15bc7))
* **ui:** added statusline component to show pending updates ([315be83](https://github.com/folke/lazy.nvim/commit/315be83afc96f5dd1f76f943de1be7d2429b5bf7))
* **ui:** added update checker ([65cd28e](https://github.com/folke/lazy.nvim/commit/65cd28e613a7b7208a3b1e61f5effc581c7b0247))


### Bug Fixes

* dev plugins with dev=false should be configured as remote ([43b303b](https://github.com/folke/lazy.nvim/commit/43b303bd8f2eb45a251e370694cc871e20d7d557))
* replace ~ by HOME for Plugin.dir ([12ded3f](https://github.com/folke/lazy.nvim/commit/12ded3f4223f3dc465e671c16ff1a537a75150fa))
* **ui:** open with noautocmd=true and close with vim.schedule to prevent weird errors by other plugins ([08d081f](https://github.com/folke/lazy.nvim/commit/08d081f21d9b54ed0b20e9a94050e3b39c75de19))


### Performance Improvements

* added profiling for sourcing of runtime files ([be509c0](https://github.com/folke/lazy.nvim/commit/be509c01f94821a6c0e5a2a4349d9160b4a4b6fe))

## [2.2.0](https://github.com/folke/lazy.nvim/compare/v2.1.0...v2.2.0) (2022-12-05)


### Features

* cleanup keys/cmd handlers when loading a plugin ([3f517ab](https://github.com/folke/lazy.nvim/commit/3f517abfa43ec9410315e205c1ee3798b66e1153))
* dont run setup again when a user re-sources their config & show a warning ([7b945ee](https://github.com/folke/lazy.nvim/commit/7b945eec588e499f0ea36974df90836549a3e734))
* **ui:** added debug interface to inspect active handlers and the module cache ([6d68cc6](https://github.com/folke/lazy.nvim/commit/6d68cc6ea20a5778fabe37ccca679d8568615a20))
* **ui:** show any helps files and added hover handler ([13b5688](https://github.com/folke/lazy.nvim/commit/13b568848775de3adfd17a410ec482c1e03da489))
* util.foreach with sorted keys ([d36ad41](https://github.com/folke/lazy.nvim/commit/d36ad410eef90bfe1a0dddd6ec1904321a5510ed))


### Bug Fixes

* always add config/after to rtp ([c98e722](https://github.com/folke/lazy.nvim/commit/c98e722fa41e0aa94809e44edf859216afedd8ad))
* **ui:** always show branch name in details ([6e44be0](https://github.com/folke/lazy.nvim/commit/6e44be0f2d543b680041be669a93377291b9132f))


### Performance Improvements

* disable cache by default on VimEnter or on BufReadPre ([b2727d9](https://github.com/folke/lazy.nvim/commit/b2727d98a3ac49cdf462e2bdf5f195dc572a91a4))

## [2.1.0](https://github.com/folke/lazy.nvim/compare/v2.0.0...v2.1.0) (2022-12-03)


### Features

* `Plugin.local` to use a local project instead of fetching remote ([0ba218a](https://github.com/folke/lazy.nvim/commit/0ba218a065c956181ff62077979e96be8bbe3d6a))
* `Plugin.specs()` can now reload and keeps existing state ([330dbe7](https://github.com/folke/lazy.nvim/commit/330dbe72031e642d2cd04b671c6eb498d96e4b71))
* added debug option ([e4cf8b1](https://github.com/folke/lazy.nvim/commit/e4cf8b141681657922643e70ec21b9f9133e9fca))
* automatically detect config module changes in or oustside Neovim and reload ([7b272b6](https://github.com/folke/lazy.nvim/commit/7b272b6ed66e21a15c6c95b00dec73be953b6554))
* for `event=`, fire any new autocmds created by loading the plugins for the event ([ebf15fc](https://github.com/folke/lazy.nvim/commit/ebf15fc198d6c82f64c17e0b752a30fd4c3cdbc7))
* moved Config.package.reset -&gt; Config.performance.reset_packpath ([fe6b0b0](https://github.com/folke/lazy.nvim/commit/fe6b0b03ead3cfeb3f9bcc365c0364346c8e3c9d))
* plugins no longer need to be installed under site/pack/*/opt ([dbe2d09](https://github.com/folke/lazy.nvim/commit/dbe2d0942a88c1211820c2e96d719c63735e976a))
* symlinking local plugins is no longer needed ([37c7366](https://github.com/folke/lazy.nvim/commit/37c7366ab02458472d97d8e35ed50583452bfe91))
* temporary colorscheme to use during install during startup ([7ec65e4](https://github.com/folke/lazy.nvim/commit/7ec65e4cd94425d08edcdab435372e4b67069d76))


### Bug Fixes

* add plugin after dir to rtp for start plugins so it gets picked up during startup ([93d3072](https://github.com/folke/lazy.nvim/commit/93d30722a011c831cce1395178b6effc1d5242de))
* **fs:** dont set cloned=true if symlink already existed ([3e143c6](https://github.com/folke/lazy.nvim/commit/3e143c6017ba3c17dd249492cc86e0d2f2750229))
* **git:** fixed branch detection, get target commit from origin and always checkout a tag or commit so we dont need to use git merge ([ae379a6](https://github.com/folke/lazy.nvim/commit/ae379a62dcaa0854086c6763672b806d3175b91c))
* respect --noplugin ([59fb050](https://github.com/folke/lazy.nvim/commit/59fb0507677628c16425dc2741f005f5394e8102))
* return nil when `fs_stat` fails and return nil in module loader ([afcba52](https://github.com/folke/lazy.nvim/commit/afcba52b1aa7f261eb37a9f6cce4e81cb44b8bec))
* source plugin files for plugins that want to run a build script during startup ([3ed24ba](https://github.com/folke/lazy.nvim/commit/3ed24baeb0c58eb24da605a57ccfdb65d1e89b47))
* temporary colorscheme should only load when installing ([ec858db](https://github.com/folke/lazy.nvim/commit/ec858db225b3fb1cc17a795ad28baa425db20061))


### Performance Improvements

* added option to reset rtp to just your config and the neovim runtime ([ccc506d](https://github.com/folke/lazy.nvim/commit/ccc506d5f71af1cce97ebde0c780f7a6454e2ace))
* caching strategy is now configurable ([6fe425c](https://github.com/folke/lazy.nvim/commit/6fe425c91acbf2b9b948b23673e22a0c61150249))

## [2.0.0](https://github.com/folke/lazy.nvim/compare/v1.2.0...v2.0.0) (2022-12-02)


### ⚠ BREAKING CHANGES

* plugins are now automatically loaded on require. `module=` no longer needed!
* all plugins are now opt. Plugin.opt => Plugin.lazy
* renamed Plugin.run => Plugin.build

### Features

* all plugins are now opt. Plugin.opt =&gt; Plugin.lazy ([5134e79](https://github.com/folke/lazy.nvim/commit/5134e797f34792e34e86fe82a72cdf765ca2e284))
* lazy setup with either a plugins module, or a plugins spec ([af8b8e1](https://github.com/folke/lazy.nvim/commit/af8b8e128e20f9fa30077bedf8bcee40b779c533))
* plugins are now automatically loaded on require. `module=` no longer needed! ([575421b](https://github.com/folke/lazy.nvim/commit/575421b3fb22731a9f97370d794fe7e3c7b57f7b))
* renamed Plugin.run =&gt; Plugin.build ([042aaa4](https://github.com/folke/lazy.nvim/commit/042aaa4f87c6576a369cbecd86aceefb96add228))
* show module source if loading source is under config ([041a716](https://github.com/folke/lazy.nvim/commit/041a716f4e5291d6947c5f96b21a2c4db0aef6e3))
* **ui:** better detection of plugins/config files that loaded a plugin ([723274e](https://github.com/folke/lazy.nvim/commit/723274efeeeddb82a5ee8ca38d456d393555ba94))
* **ui:** improvements to profiling and rendering of loaded reasons ([714bc0a](https://github.com/folke/lazy.nvim/commit/714bc0a136cd72730e1c457556fbe004a22db6b7))


### Bug Fixes

* always overwrite any plugin spec for lazy.nvim to manage itself ([d46bc77](https://github.com/folke/lazy.nvim/commit/d46bc7795c255f121d2d279764017c7d60edff88))
* prepend package path to packpath if package.reset=false ([5eb2622](https://github.com/folke/lazy.nvim/commit/5eb2622a4e4e52bed94b5c8ae48b83ccfab0098d))
* **ui:** use Plugin.find to detect loading reason ([98ccf55](https://github.com/folke/lazy.nvim/commit/98ccf556d8c1e6a8eadb004620c9d5e95733285a))


### Performance Improvements

* module now caches all lua modules used till VimEnter ([0b6dec4](https://github.com/folke/lazy.nvim/commit/0b6dec46e02b2f56ac5c180d6a809f140e50ddf6))
* reset packpath to only include the lazy package. Improved my startup time by 2ms ([4653119](https://github.com/folke/lazy.nvim/commit/4653119625fa8e8c647f6c0ff0b0b57ee81521b8))

## [1.2.0](https://github.com/folke/lazy.nvim/compare/v1.1.0...v1.2.0) (2022-11-30)


### Features

* added config option for process timeout ([bd2d642](https://github.com/folke/lazy.nvim/commit/bd2d64230fc0fe931fa480f4c6a61f507fbbd2ca))
* allow config of default for version field ([fb96183](https://github.com/folke/lazy.nvim/commit/fb96183753bfc734b081fc5a2a3d5705376d9d20))
* config for ui border ([0cff878](https://github.com/folke/lazy.nvim/commit/0cff878b2e1af134892184920fd8ae64d9f954c0))
* config option for runner concurrency ([b2339ad](https://github.com/folke/lazy.nvim/commit/b2339ade847d2ccf5e898edb7cca0bca20e635a3))
* config option for ui throttle ([a197f75](https://github.com/folke/lazy.nvim/commit/a197f751f97c1b050916a8453acba914569b7bb5))
* config option install_missing=true ([9be3d3d](https://github.com/folke/lazy.nvim/commit/9be3d3d8409c6992cea5b2ffe0973fd6b4895dc6))


### Bug Fixes

* show proper installed/clean state for local plugins ([1e2f527](https://github.com/folke/lazy.nvim/commit/1e2f5273bb61b660dd93651c4fc44d2c8c21b905))
* update state after running operation so the ui reflects any changes from cleaning ([0369278](https://github.com/folke/lazy.nvim/commit/03692781597b648fa3524e50c0de4bff405ba215))


### Performance Improvements

* merge module/cache and use ffi to pack cache data ([e1c08d6](https://github.com/folke/lazy.nvim/commit/e1c08d64b387c59343c21a6f0397b88d5b4a3acc))
* removed partial spec caching. not worth the tiny performance boost ([4438faf](https://github.com/folke/lazy.nvim/commit/4438faf9a9a72c95d88c620804db99fa44485ec9))
* run cache autosave after loading ([3ec5a2c](https://github.com/folke/lazy.nvim/commit/3ec5a2ce4c99202dfa76970bbaa36bfa05230cb5))

## [1.1.0](https://github.com/folke/lazy.nvim/compare/v1.0.0...v1.1.0) (2022-11-29)


### Features

* dependencies are opt=true by default if they only appear as a dep ([908b9ad](https://github.com/folke/lazy.nvim/commit/908b9adf9c5a3bc5fd26e0b4900f88faee16f731))
* lazy handler implies opt=true ([b796abc](https://github.com/folke/lazy.nvim/commit/b796abcc33e43a012983cc82f01e3bedd9f3c365))


### Bug Fixes

* make sure Plugin.opt is always a boolean ([ca78dd7](https://github.com/folke/lazy.nvim/commit/ca78dd77ac39ca21f1386292f338a87b47ffa84b))


### Performance Improvements

* dont loop over handlers to determine if a plugin should be opt=true ([812bb3c](https://github.com/folke/lazy.nvim/commit/812bb3c8b76e5102d7d391fd7bbfcdfd0bbe506b))

## 1.0.0 (2022-11-29)


### ⚠ BREAKING CHANGES

* added icons

### Features

* a gazilion rendering improvements ([a11fc5a](https://github.com/folke/lazy.nvim/commit/a11fc5a0e0229b9394946296a5cc241db788f476))
* added "Lazy check" to check for updates without updating ([63cf2a5](https://github.com/folke/lazy.nvim/commit/63cf2a52bd46019914fc41160c9601db06fdd469))
* added bootstrap code ([ceeeda3](https://github.com/folke/lazy.nvim/commit/ceeeda36e89a4f048903e051d9fece5222be087e))
* added full semver and range parsing ([f54c24a](https://github.com/folke/lazy.nvim/commit/f54c24a4fac6d261dc6ebd72d64aa8ceaab9aa12))
* added icons ([c046b1f](https://github.com/folke/lazy.nvim/commit/c046b1f5d5e31904f5ee4c2d24b484246fc09e08))
* added keybindings to update/install/clean/restore/... single plugins ([08b7e42](https://github.com/folke/lazy.nvim/commit/08b7e42fb0743da4fb4221f51d28bd8b108ee25f))
* added lockfile support ([4384d0e](https://github.com/folke/lazy.nvim/commit/4384d0e6d918b7db0cdaebbf0f3b0a4230c84120))
* added profiler view ([20ff5fa](https://github.com/folke/lazy.nvim/commit/20ff5fa218b4a27194fee0b3d023e92f797cd34d))
* added section with logs containing breaking changes ([d7dbe1a](https://github.com/folke/lazy.nvim/commit/d7dbe1a43f712065b71c6da35d75b23deba1ffe1))
* added support for Plugin.lock (wont update) ([0774f1b](https://github.com/folke/lazy.nvim/commit/0774f1bc255e91bf16c426908cd50ed038b21305))
* added vimdoc/release-please/tests ([e9a1e9f](https://github.com/folke/lazy.nvim/commit/e9a1e9fe19d6180d5f1e65fd9375b6c333f5159e))
* default log is last 10 entries ([54a82ad](https://github.com/folke/lazy.nvim/commit/54a82ad69566c99110976c644a181bf5a381b998))
* detect headless and set interactive=false ([bad1b1f](https://github.com/folke/lazy.nvim/commit/bad1b1f87d3a6dc5ae4b5cdcb1eda7dd79b511f1))
* error handler for loading modules, config and init, with custom error formatting ([7933ae1](https://github.com/folke/lazy.nvim/commit/7933ae11c437e9ab5a42cfd729994c52f503b132))
* git log ([3218c2d](https://github.com/folke/lazy.nvim/commit/3218c2d9ec6f88f00d46775f67c1b2dca436af4c))
* git log config ([3e4f846](https://github.com/folke/lazy.nvim/commit/3e4f84640eaee485c130b303d71cbf847650473a))
* initial commit ([e73626a](https://github.com/folke/lazy.nvim/commit/e73626a3444cef85c6e191989b97d5deb8d2befd))
* keep track what loaded a plugin ([4df73f1](https://github.com/folke/lazy.nvim/commit/4df73f167dfba7958abae393f72bbe2a5e5a663a))
* lazy caching now works with functions that have upvalues ([fe33e4e](https://github.com/folke/lazy.nvim/commit/fe33e4e3dde934b3ddade619e9982cd1d54713b0))
* lazy commands ([ae0b871](https://github.com/folke/lazy.nvim/commit/ae0b87181db0ac10b60cfb35c8f4691234444a9d))
* lazy view ([a87982f](https://github.com/folke/lazy.nvim/commit/a87982ff1525f3f54a716175bf0b8f73a82a491c))
* load plugin on cmd complete and make completion just work ([2080694](https://github.com/folke/lazy.nvim/commit/2080694e3402980d7b84fa095bfdd084002d64c7))
* lots of improvements to pipeline runner and converted all tasks to new system ([fb84c08](https://github.com/folke/lazy.nvim/commit/fb84c081b0f1b5d42b2edf9f66fd2cc2db3a0a7e))
* new git module to work with branches, tags & versions ([2abdc68](https://github.com/folke/lazy.nvim/commit/2abdc681fad811895a744dac09009db25cf92f6e))
* new render features like profile etc ([48199f8](https://github.com/folke/lazy.nvim/commit/48199f803189284b9585b96066f84d3805cce6b1))
* new task pipeline runner ([ab1b512](https://github.com/folke/lazy.nvim/commit/ab1b512545fd1a4fd3e6742d5cb7d13b7bcd92ff))
* plugin manager tasks ([a612e6f](https://github.com/folke/lazy.nvim/commit/a612e6f6f4ffbcef6ae7f94955ac406d436284d8))
* return whether a module was loaded from cache or from file (dirty) ([38e2711](https://github.com/folke/lazy.nvim/commit/38e2711cdb8c342c9d6687b22f347d7038094011))
* task docs and options for logs ([fe6d0b1](https://github.com/folke/lazy.nvim/commit/fe6d0b1745cb8171c441e81168df23a09238fc9e))
* **text:** center text ([88869e6](https://github.com/folke/lazy.nvim/commit/88869e67d2f06c7778b9bdbf57681615d3d41f11))
* **text:** multiline support and pattern highlights ([815bb2c](https://github.com/folke/lazy.nvim/commit/815bb2ce6cdc359115a7e65021a21c3347e8a5f6))
* url open handlers ([6f835ab](https://github.com/folke/lazy.nvim/commit/6f835ab87b5f8ecef630cd9b024fac03795bb674))
* util.info ([e59dc37](https://github.com/folke/lazy.nvim/commit/e59dc377d5e30df8edc471f2cb74dbdd9cf8039d))
* **view:** modes and help ([0db98bf](https://github.com/folke/lazy.nvim/commit/0db98bf053fcbe04926e6773897a5e811b82c293))


### Bug Fixes

* always recaclulate hash when loading a module ([cfc3933](https://github.com/folke/lazy.nvim/commit/cfc39330dc022543052ef66d38cb15697b4fc0e4))
* check for lazy before setting loading time ([30bdc9b](https://github.com/folke/lazy.nvim/commit/30bdc9b5a1b4c54128a1cb30dbab5cb8bb6a67b3))
* clean ([7f4743a](https://github.com/folke/lazy.nvim/commit/7f4743ac304bfb762f5d03dd2d691cf4bba933e2))
* correctly handle changes from local to remote plugin ([4de10f9](https://github.com/folke/lazy.nvim/commit/4de10f9578d49fe7fffb64a0fcd3ee55d9ea89aa))
* decompilation fixes ([57d024e](https://github.com/folke/lazy.nvim/commit/57d024ef196cbd0d7166703218726418e33184b9))
* dont return init.lua in lsmod ([413dd5b](https://github.com/folke/lazy.nvim/commit/413dd5b112e57bd57fbf93509cb3dcbdc430fb8d))
* first line of file ([c749404](https://github.com/folke/lazy.nvim/commit/c7494044236a2753deb53a81db02f06cc308d47a))
* get current branch if remote head not available (for local repos only) ([d486bc5](https://github.com/folke/lazy.nvim/commit/d486bc586b6a711af64444c4cec52b8b1590295c))
* highlights ([35b1f98](https://github.com/folke/lazy.nvim/commit/35b1f98ac756ec31459d366aa363d693adb27647))
* log errors in runner ([7303017](https://github.com/folke/lazy.nvim/commit/7303017b6f4ee7b72b86b8c12ee29bf1c2bd8381))
* make sure we have ran on_exit before returning is_done=true ([782d287](https://github.com/folke/lazy.nvim/commit/782d287d891522dec8e460297f81cb5a8fbe33dc))
* manage opts show =&gt; interactive ([93a3a6c](https://github.com/folke/lazy.nvim/commit/93a3a6ccb55055c50dec22fdf0dd11b890defdb4))
* only save state when dirty ([32ca1c4](https://github.com/folke/lazy.nvim/commit/32ca1c4bf875b10776ad8a928e43df290d11cd42))
* recalculate loaders on config file change ([870d892](https://github.com/folke/lazy.nvim/commit/870d8924f76f98da7b436e4baaa2f3c4f0f4f442))
* reset diagnostics when lazy view buffer closes ([04dea38](https://github.com/folke/lazy.nvim/commit/04dea38794547cef79d40e56667fd0c9909cf1f1))
* show view with schedule to prevent Neovim crash when no plugins are installed ([5d84967](https://github.com/folke/lazy.nvim/commit/5d84967e9c011e32e1e9b482f95314df8dfc0e27))
* support adding top-level lua directories ([7288962](https://github.com/folke/lazy.nvim/commit/72889623af0e2ee461d2ec6e5f2fee39e81fd1c2))
* support local files as plugin spec ([0233460](https://github.com/folke/lazy.nvim/commit/0233460d5422a18ecee5b25bc782321f398835c4))
* **tasks:** always set updated on checkout. Change default logging to 3 days ([5bcdddc](https://github.com/folke/lazy.nvim/commit/5bcdddc0ecb28f7d6832767ca142de442a514581))
* **view:** handler details ([bbad0cb](https://github.com/folke/lazy.nvim/commit/bbad0cb8917f1e48c519bf978bfa4d4900131d49))
* when just cloned, never commit lock ([32fa5f8](https://github.com/folke/lazy.nvim/commit/32fa5f84412804a08a71846c121fbb0bbb915322))


### Performance Improvements

* cache handler groups ([42c2fb4](https://github.com/folke/lazy.nvim/commit/42c2fb42c8b466ea1ffe0a9248664419a917a265))
* copy reason without deepcopy ([72d51ce](https://github.com/folke/lazy.nvim/commit/72d51cee9b4b8c43539aa08e5c17a9ef5bc4e84b))
* fast return for Util.ls when file found ([073b5e3](https://github.com/folke/lazy.nvim/commit/073b5e3caaf6c2b5b69793ed255fe73680d3d6e2))
* further optims to loading and caching specs. dont cache specs with plugin that have init or in start with config ([8790070](https://github.com/folke/lazy.nvim/commit/879007087163ef8bd8c6fd86edc82133cec6a416))
* split caching in state, cache and module ([54d5ff1](https://github.com/folke/lazy.nvim/commit/54d5ff18f573057afd6427b62e6ae5dc241acc16))
* tons of performance improvements. Lazy should now load in about 1.5ms for 97 plugins ([2507fd5](https://github.com/folke/lazy.nvim/commit/2507fd5790db8917f01088ef3875a512962ffdca))
* way better compilation and caching ([a543134](https://github.com/folke/lazy.nvim/commit/a543134b8c1b17c2396a757b08951b6d91b14402))
