# Changelog

## [9.6.0](https://github.com/folke/lazy.nvim/compare/v9.5.1...v9.6.0) (2023-02-07)


### Features

* **cmd:** use cmd table instead of trying to create the cmd string. Fixes [#472](https://github.com/folke/lazy.nvim/issues/472) ([3c29f19](https://github.com/folke/lazy.nvim/commit/3c29f196f4b0f083f2b94c3337599a189f4eef84))

## [9.5.1](https://github.com/folke/lazy.nvim/compare/v9.5.0...v9.5.1) (2023-02-06)


### Bug Fixes

* **commands:** sync with plugins list should not delete those plugins. Fixes [#475](https://github.com/folke/lazy.nvim/issues/475) ([0c98031](https://github.com/folke/lazy.nvim/commit/0c980312fd6bce744db499acfa5af47871287151))
* **health:** existing packages on windows. Fixes [#474](https://github.com/folke/lazy.nvim/issues/474) ([527f83c](https://github.com/folke/lazy.nvim/commit/527f83cae50b99d16327447eb813b4f73e09ec0d))
* **log:** properly check if plugin dir is a git repo before running git log ([3d2dcb2](https://github.com/folke/lazy.nvim/commit/3d2dcb2d5ef99106c5ff412da88c6f59a9f8a693))
* **process:** allow overriding GIT_SSH_COMMAND. Fixes [#491](https://github.com/folke/lazy.nvim/issues/491). Fixes [#492](https://github.com/folke/lazy.nvim/issues/492) ([452d4eb](https://github.com/folke/lazy.nvim/commit/452d4eb719c5067f0bae497dc870554cd300758f))

## [9.5.0](https://github.com/folke/lazy.nvim/compare/v9.4.0...v9.5.0) (2023-01-24)


### Features

* **config:** added option to disable git filter. NOT recommended. Fixes [#442](https://github.com/folke/lazy.nvim/issues/442) ([26a67e3](https://github.com/folke/lazy.nvim/commit/26a67e3c48951ca3ce47d208c3216143749b0768))
* **dev:** optionally fallback to git when local plugin doesn't exist ([#446](https://github.com/folke/lazy.nvim/issues/446)) ([772d888](https://github.com/folke/lazy.nvim/commit/772d8888cc6f8e4371c31001197431b24311af48))
* **health:** check for git in health checks ([9b5cc1b](https://github.com/folke/lazy.nvim/commit/9b5cc1bf53f344c8ad829f33c3ac77f5e3ea8da1))
* **util:** utility method to walk over all modules in a directory ([5d9d354](https://github.com/folke/lazy.nvim/commit/5d9d35404f39de5d7c9365cbc2aa39858929cbfc))


### Bug Fixes

* **checker:** dont check for updates when there's tasks with errors ([c32a618](https://github.com/folke/lazy.nvim/commit/c32a6185ace7cb04572db1637a3010b729a7601e))
* **checker:** dont clear tasks when running update check ([ed21070](https://github.com/folke/lazy.nvim/commit/ed210702f5dc8c24ec6531c0f2484881d9ebe6b6))

## [9.4.0](https://github.com/folke/lazy.nvim/compare/v9.3.1...v9.4.0) (2023-01-22)


### Features

* added `config.ui.wrap` and improved wrapping when wrap=true. Fixes [#422](https://github.com/folke/lazy.nvim/issues/422) ([d6fc848](https://github.com/folke/lazy.nvim/commit/d6fc848067d603800b9e63a7b22b7e5853c6bd7a))
* **checker:** checker will now save last check time and only check at configured frequency even after restarting Neovim ([813fc94](https://github.com/folke/lazy.nvim/commit/813fc944d797fe1b43abe12866a9ef7af403c35c))


### Bug Fixes

* **checker:** make sure we show logs when only doing a fast check ([4008b57](https://github.com/folke/lazy.nvim/commit/4008b57d882065814ce27a0f32609d5ea437a6e9))
* **git:** unset GIT_DIR when spawning a process. Fixes [#434](https://github.com/folke/lazy.nvim/issues/434) ([9858001](https://github.com/folke/lazy.nvim/commit/9858001c3cdb5713e8d1aeb0f47c23038084fd7c))
* **render:** get profile_{sort,filter} key bindings from ViewConfig ([#416](https://github.com/folke/lazy.nvim/issues/416)) ([27ca918](https://github.com/folke/lazy.nvim/commit/27ca918bc3d02ea20b3fd901c8919e9925555444))
* **spec:** dont complain about an invalid short url, when a full url is set. Fixes [#421](https://github.com/folke/lazy.nvim/issues/421) ([c389ad5](https://github.com/folke/lazy.nvim/commit/c389ad552bd5c2050783ac6cd6e54f5fbba3c7bc))

## [9.3.1](https://github.com/folke/lazy.nvim/compare/v9.3.0...v9.3.1) (2023-01-17)


### Bug Fixes

* **git:** when a `Plugin.branch` is set, don't use `config.defaults.version`. Fixes [#409](https://github.com/folke/lazy.nvim/issues/409) ([bd37afc](https://github.com/folke/lazy.nvim/commit/bd37afc96e4d64a41744298f24772dddb5286fd5))
* **spec:** dont copy dep and super state from existing plugins ([da4e8cc](https://github.com/folke/lazy.nvim/commit/da4e8cc2450ec428d370032b5b3790b01889c4a4))
* **spec:** when overriding a spec by name that has not been imported yet, show an error when needed ([baaf8dd](https://github.com/folke/lazy.nvim/commit/baaf8ddfff6cf0c2b8729c2b76b2b140cb40d382))
* work-around for libuv issue where fs_scandir_next sometimes fails to return a file type ([c791c0e](https://github.com/folke/lazy.nvim/commit/c791c0ed7d7bbcdc06a58b79eb4625682c60964c))


### Performance Improvements

* **plugin:** de-duplicate dependencies, keys, ft, event and cmd ([1b2a6f6](https://github.com/folke/lazy.nvim/commit/1b2a6f631c9b2ef98005acec8369c7298fe7a751))

## [9.3.0](https://github.com/folke/lazy.nvim/compare/v9.2.0...v9.3.0) (2023-01-16)


### Features

* **git:** some debugging tools for git ([208f91b](https://github.com/folke/lazy.nvim/commit/208f91b52fff5f7b6120b19b80e529821d70d009))
* **keys:** allow overriding a keys value to `vim.NIL` to not add the key ([fdf0332](https://github.com/folke/lazy.nvim/commit/fdf0332fe17d9c01f92a8464c04213123a025a07))
* **spec:** overriding keys with an rhs of `false` will remove the key instead ([870af80](https://github.com/folke/lazy.nvim/commit/870af80c68f3834ffcbced1528cce6197ec2b4ae))
* **spec:** you can now override specs using only the plugin name instead of the short url ([0cbd91d](https://github.com/folke/lazy.nvim/commit/0cbd91d2cd942cc448b4648dbc7ba57515a2867c))


### Bug Fixes

* **build:** make sure `rplugin.vim` is loaded when doing a build. Fixes [#382](https://github.com/folke/lazy.nvim/issues/382) ([666ed7b](https://github.com/folke/lazy.nvim/commit/666ed7bf73eb5895253c1155bd29270b066cbdac))
* **loader:** load plugin opts inside a `try` clause to report errors ([7160ca4](https://github.com/folke/lazy.nvim/commit/7160ca419e7be36536dd8fe90ad0bf26cdd773ae))
* **util:** rever ([e8cb863](https://github.com/folke/lazy.nvim/commit/e8cb863703276c579d781b7e4e0b27052df8fc68))


### Performance Improvements

* **util:** dont trigger VeryLazy autocmds when exiting ([1e67dc0](https://github.com/folke/lazy.nvim/commit/1e67dc0d56b8e7cf6befdc7176a4a54e17afc244))
* **util:** properly check that Neovim is exiting. Dont run VeryLazy when that's the case ([efe72d9](https://github.com/folke/lazy.nvim/commit/efe72d98e6fb71252bd9a904c00a40ccd54ebf05))

## [9.2.0](https://github.com/folke/lazy.nvim/compare/v9.1.3...v9.2.0) (2023-01-13)


### Features

* **commands:** allow commands like `Lazy ... | ...` ([#377](https://github.com/folke/lazy.nvim/issues/377)) ([7b78ce3](https://github.com/folke/lazy.nvim/commit/7b78ce33327c3caee9a0933792b432bce5c6c885))
* **spec:** event, keys, ft and cmd can now also be a function that returns the values to be used ([2128ca9](https://github.com/folke/lazy.nvim/commit/2128ca90fb67928e5e23590142de9c94fc0a0d31))


### Bug Fixes

* **cache:** de-duplicate topmods. Fixes [#349](https://github.com/folke/lazy.nvim/issues/349) ([81017b9](https://github.com/folke/lazy.nvim/commit/81017b99e799d08ea5297b0f620e4404ef41e51f))
* **float:** only clear diagnostics for valid buffers ([7b0d1a7](https://github.com/folke/lazy.nvim/commit/7b0d1a786664a707accfde09ecf54315e91f9a2b))
* **ui:** open diff and others over the ui. Don't try to be smart about it. Fixes [#361](https://github.com/folke/lazy.nvim/issues/361) ([3fbe4fe](https://github.com/folke/lazy.nvim/commit/3fbe4fe27ab6b58e5dafd45c5316ec62791907d4))
* use `vim.api.nvim_exec_autocmds` instead of `vim.cmd[[do]]` to prevent weird `vim.notify` behavior ([b73312a](https://github.com/folke/lazy.nvim/commit/b73312aa32c685ff68771a31d209a43866e4d4b2))

## [9.1.3](https://github.com/folke/lazy.nvim/compare/v9.1.2...v9.1.3) (2023-01-11)


### Bug Fixes

* **cache:** use cached chunk when specs are loading for valid plugins ([07fd7ad](https://github.com/folke/lazy.nvim/commit/07fd7adb3427ac510c33de308cd5dfcc6ba701b6))
* **loader:** prevent loading plugins when loading specs ([e1cd9cd](https://github.com/folke/lazy.nvim/commit/e1cd9cd0adfb04432ffaf3d8bd54a5b409eb4273))

## [9.1.2](https://github.com/folke/lazy.nvim/compare/v9.1.1...v9.1.2) (2023-01-11)


### Bug Fixes

* **handlers:** allow overriding handler values ([74bc61a](https://github.com/folke/lazy.nvim/commit/74bc61ab97c3bc2e73e19d269f23076d50c3285f))
* **ui:** possible error during initial install ([a646238](https://github.com/folke/lazy.nvim/commit/a64623899db9fe1a41c8bf86562feed6d4757ba0))
* **ui:** properly position Lazy tabs when opening another cmd. Fixes [#361](https://github.com/folke/lazy.nvim/issues/361) ([8756c09](https://github.com/folke/lazy.nvim/commit/8756c0950ca9053713262abd1092f6d100adc9a5))
* **ui:** reset buf and win options on resize ([3b44c3c](https://github.com/folke/lazy.nvim/commit/3b44c3c14ad69e7a26ae6408816f332af58202c3))


### Performance Improvements

* **util:** execute VeryLazy right after UIEnter ([5aca928](https://github.com/folke/lazy.nvim/commit/5aca9280df4245df8bf8e33fe9bc4ce85507dc31))

## [9.1.1](https://github.com/folke/lazy.nvim/compare/v9.1.0...v9.1.1) (2023-01-10)


### Bug Fixes

* **ui:** get_plugin should return when ui is not showing ([5faadf6](https://github.com/folke/lazy.nvim/commit/5faadf6398f99f781a212d2a7cbd39a688d32300))

## [9.1.0](https://github.com/folke/lazy.nvim/compare/v9.0.0...v9.1.0) (2023-01-10)


### Features

* **spec:** allow git@ and http urls in `Plugin[1]` without `url=`. Fixes [#357](https://github.com/folke/lazy.nvim/issues/357) ([4304035](https://github.com/folke/lazy.nvim/commit/4304035ef4eae2d9dfac4fc082a1b391e6cd928e))
* **util:** `Util.merge` now support advanced merging strategies. Docs coming soon ([b28c6b9](https://github.com/folke/lazy.nvim/commit/b28c6b900030556e4e72f2ce68abae0e7292a3bf))


### Bug Fixes

* **cache:** dont keep invalid entries in the cache (cleanup) ([9fa62ea](https://github.com/folke/lazy.nvim/commit/9fa62ea8ea935dec7078587c3664047db2065bf2))
* **diffview:** fixed parameter for showing single commit with DiffView. Fixes [#304](https://github.com/folke/lazy.nvim/issues/304) ([a32e307](https://github.com/folke/lazy.nvim/commit/a32e307981519a25dd3f05a33a6b7eea709f0fdc))
* **docs:** auto-gen of readme stuff ([3a216d0](https://github.com/folke/lazy.nvim/commit/3a216d008def355813ede7deb5392276b7e3c10c))
* **spec:** `Plugin.opts` is now always a table. Fixes [#351](https://github.com/folke/lazy.nvim/issues/351) ([e77be3c](https://github.com/folke/lazy.nvim/commit/e77be3cf3b01402b86464e1734fb5ead448ce12e))
* **spec:** don't import specs more than once ([ad7aafb](https://github.com/folke/lazy.nvim/commit/ad7aafb257516cefff85aceb5d36041090b40559))
* **ui:** keymap for building a single plugin changed from `b` to `gb`. Fixes [#358](https://github.com/folke/lazy.nvim/issues/358) ([e6ee0fa](https://github.com/folke/lazy.nvim/commit/e6ee0fa6103e9514e85a96fc16902ad7f777b53f))

## [9.0.0](https://github.com/folke/lazy.nvim/compare/v8.1.0...v9.0.0) (2023-01-08)


### ⚠ BREAKING CHANGES

* **spec:** setting a table to `Plugin.config` is now deprecated. Please use `Plugin.opts` instead. (backward compatible for now)

### Features

* **git:** added fast `Git.get_origin` and `Git.get_config` ([a39fa0f](https://github.com/folke/lazy.nvim/commit/a39fa0f0ced7324800eff0a4eb0ed68bf13452d1))
* **git:** lazy now detects origin changes and will fix it on update. Fixes [#346](https://github.com/folke/lazy.nvim/issues/346). Fixes [#331](https://github.com/folke/lazy.nvim/issues/331) ([615781a](https://github.com/folke/lazy.nvim/commit/615781aebfc0230669a2e5750cba3c65f0b8a90e))
* **spec:** setting a table to `Plugin.config` is now deprecated. Please use `Plugin.opts` instead. (backward compatible for now) ([7260a2b](https://github.com/folke/lazy.nvim/commit/7260a2b28be807c4bdc1caf23fa35c2aa33aa6ac))
* **util:** better deep merging with `Util.merge` ([6a31b97](https://github.com/folke/lazy.nvim/commit/6a31b97e3729af3710207642968e1492071a7dbc))

## [8.1.0](https://github.com/folke/lazy.nvim/compare/v8.0.0...v8.1.0) (2023-01-07)


### Features

* **spec:** show error when loading two specs with the same name and a different url. Fixes [#337](https://github.com/folke/lazy.nvim/issues/337) ([c313249](https://github.com/folke/lazy.nvim/commit/c3132492714661121f70daf77d716053ab39bd0b))


### Bug Fixes

* **cache:** check that modpaths still exist when finding mod root ([d34c85d](https://github.com/folke/lazy.nvim/commit/d34c85d58007f37f9eb60fe0c1075950a5ce615e))
* **config:** Don't cache check for attached UIs ([#340](https://github.com/folke/lazy.nvim/issues/340)) ([05b55de](https://github.com/folke/lazy.nvim/commit/05b55deb16f074f2a44b81927c2e5feb63fba651))
* **config:** properly handle uis connecting after startup ([5ed89b5](https://github.com/folke/lazy.nvim/commit/5ed89b5a0d6be65ec9fd0f6526c8c27a922f50a1))

## [8.0.0](https://github.com/folke/lazy.nvim/compare/v7.12.1...v8.0.0) (2023-01-06)


### ⚠ BREAKING CHANGES

* **util:** `require("lazy.util").open_cmd()` is deprecated. See the docs

### Features

* **commands:** `:Lazy! load` now skips `cond` checks when loading plugins. Fixes [#330](https://github.com/folke/lazy.nvim/issues/330) ([eed1ef3](https://github.com/folke/lazy.nvim/commit/eed1ef3c2d13b374def716ed7e9997595c466b3f))


### Bug Fixes

* **loader:** revert change that loaded /plugin after config. Fixes [#328](https://github.com/folke/lazy.nvim/issues/328) ([2ef44e2](https://github.com/folke/lazy.nvim/commit/2ef44e2dee112ba7b83bdfca98f6c07967d65484))
* **loader:** source runtime files without `silent`. Fixes [#336](https://github.com/folke/lazy.nvim/issues/336) ([102bc27](https://github.com/folke/lazy.nvim/commit/102bc2722e73d0dcebd6c90b45a41cb33e0660cb))


### Code Refactoring

* **util:** `require("lazy.util").open_cmd()` is deprecated. See the docs ([4f76b43](https://github.com/folke/lazy.nvim/commit/4f76b431f73c912a7021bc17384533fbad96fba7))

## [7.12.1](https://github.com/folke/lazy.nvim/compare/v7.12.0...v7.12.1) (2023-01-05)


### Bug Fixes

* **cache:** check full paths of cached modpaths. Fixes [#324](https://github.com/folke/lazy.nvim/issues/324) ([b2dec14](https://github.com/folke/lazy.nvim/commit/b2dec14824383137440040da0d9d107f3a29c656))
* **loader:** run plugin config before sourcing runtime ([c59c05c](https://github.com/folke/lazy.nvim/commit/c59c05c7a80693fda369ccab572f8eaca50a1b4f))
* **util:** Util.try can now work without an error message ([e4f79a4](https://github.com/folke/lazy.nvim/commit/e4f79a42d650c926ea12edb7dbe2efbe1031b723))

## [7.12.0](https://github.com/folke/lazy.nvim/compare/v7.11.0...v7.12.0) (2023-01-04)


### Features

* **spec:** allow import property on a plugin spec ([dea43af](https://github.com/folke/lazy.nvim/commit/dea43afc4adff21a6d5864a378459a140a702c0c))


### Bug Fixes

* **keys:** Use vim's default value for an unset g:mapleader ([#316](https://github.com/folke/lazy.nvim/issues/316)) ([3bde7b5](https://github.com/folke/lazy.nvim/commit/3bde7b5ba8b99941b314a75d8650a0a6c8552144))

## [7.11.0](https://github.com/folke/lazy.nvim/compare/v7.10.0...v7.11.0) (2023-01-04)


### Features

* **loader:** disable plugins ([a7ac2ad](https://github.com/folke/lazy.nvim/commit/a7ac2ad0204d63ece6ebca76ae906db53346c8a4))
* **spec:** spec merging now properly works with `Plugin.enabled` ([81cb352](https://github.com/folke/lazy.nvim/commit/81cb352fe6150570b7dd7266e3053869ce40babc))


### Bug Fixes

* **diff:** make diffview work again. Fixes [#304](https://github.com/folke/lazy.nvim/issues/304) ([e61b334](https://github.com/folke/lazy.nvim/commit/e61b334cee143ebb136125d6faa0f18dc35eb6c0))
* **keys:** only replace localleader and maplocalleader. Fixes [#307](https://github.com/folke/lazy.nvim/issues/307), fixes [#308](https://github.com/folke/lazy.nvim/issues/308) ([507b695](https://github.com/folke/lazy.nvim/commit/507b695753b4a7e1eff75f578b7a04b6307e4bc6))
* **loader:** dont show error of missing plugins if they are disabled ([09fd8fa](https://github.com/folke/lazy.nvim/commit/09fd8fabd29eb6da82c3eb2be4b270f9de9b4d8c))
* **loader:** move mapleader check to loader, so it can be set by spec files ([b4d4e6b](https://github.com/folke/lazy.nvim/commit/b4d4e6b41b0b5110019dc247db994ae294f23b77))
* **util:** assume type is file when no type is returned by scandir. Fixes [#306](https://github.com/folke/lazy.nvim/issues/306) ([2e87520](https://github.com/folke/lazy.nvim/commit/2e875208268f0bbc9927bb9b245b00031b6c07d9))


### Performance Improvements

* **spec:** more efficient merging of specs and added `Plugin._.super` ([bce0c6e](https://github.com/folke/lazy.nvim/commit/bce0c6e327c953c644c20c043303826340596e8e))

## [7.10.0](https://github.com/folke/lazy.nvim/compare/v7.9.0...v7.10.0) (2023-01-03)


### Features

* **spec:** allow overriding `Plugin.enabled` ([05aec48](https://github.com/folke/lazy.nvim/commit/05aec48968f91803a53704c04f3fad3c64033256))
* **ui:** added section with disabled plugins ([299ffdf](https://github.com/folke/lazy.nvim/commit/299ffdfd538938e3241998de65d0a175fcf73f48))
* **version:** allow version=false to override default version ([f36c7cb](https://github.com/folke/lazy.nvim/commit/f36c7cb0dc39d1bc3d0ae56d096afd9012a25607))


### Bug Fixes

* **git:** better errors when a branch/tag/version could not be found. Fixes [#276](https://github.com/folke/lazy.nvim/issues/276) ([277a2ab](https://github.com/folke/lazy.nvim/commit/277a2ab10baeebf64548a6b5a606d7b82f8e3165))
* **git:** properly compare git commits with short refs ([dc9c92a](https://github.com/folke/lazy.nvim/commit/dc9c92a9b37352eab36d5c4ff4542b7b3c927b6f))
* **health:** check for all packages on the rtp, excluding `dist` packs ([1c854d7](https://github.com/folke/lazy.nvim/commit/1c854d7a6d37d7b2ab6926605e7341696c77fd6c))
* **install:** dont try re-installing failed missing plugins during startup. Fixes [#303](https://github.com/folke/lazy.nvim/issues/303) ([c85f929](https://github.com/folke/lazy.nvim/commit/c85f929bd98032b35e09fbc5a510884caaa8a5c3))
* **keys:** make operator pending mode work. Fixes [#286](https://github.com/folke/lazy.nvim/issues/286) ([cdb998c](https://github.com/folke/lazy.nvim/commit/cdb998c6fec617b76063ff64e6e44eac7d0b6b7e))
* **keys:** operator ([2e3e65b](https://github.com/folke/lazy.nvim/commit/2e3e65b0f7b16773f5f83ee4eea09fe6bca653cd))
* **keys:** operator pending mode ([e93f50f](https://github.com/folke/lazy.nvim/commit/e93f50fd1b49f09725ecd310a3cce2cd860ff5a0))
* **spec:** show error when users load a plugins module called `lazy` ([1fd8015](https://github.com/folke/lazy.nvim/commit/1fd80159d074e5c22b946d9b87f274a243ecf213))
* **stats:** fixed cputime on linux ([06db1ec](https://github.com/folke/lazy.nvim/commit/06db1ec3c6baa9460e42ef8ed4d2cc2613b194cb))
* **stats:** more robust checks for native cputime ([b5f4106](https://github.com/folke/lazy.nvim/commit/b5f4106892254c748c49a42e07acd80964cb0bce))
* **stats:** use fallback for cputime on windows. Fixes [#280](https://github.com/folke/lazy.nvim/issues/280) ([ddcdc5e](https://github.com/folke/lazy.nvim/commit/ddcdc5e4472a5f9e0ead8afd38e4fed2ec882617))
* **stats:** windows ([85173dc](https://github.com/folke/lazy.nvim/commit/85173dcc4d7a39e67370571316a6290f31a0de4a))
* **ui:** check if win is still valid ([e749e68](https://github.com/folke/lazy.nvim/commit/e749e68b68b66d7f1c8284941b8cca9fd3cd9482))
* **util:** made `Util.lsmod` more robust. See [#298](https://github.com/folke/lazy.nvim/issues/298) ([953c279](https://github.com/folke/lazy.nvim/commit/953c2791d8c391bf720ae68e734078bb558329f6))

## [7.9.0](https://github.com/folke/lazy.nvim/compare/v7.8.0...v7.9.0) (2023-01-02)


### Features

* **commands:** added build command to force rebuild of a plugin ([23c0587](https://github.com/folke/lazy.nvim/commit/23c0587791607bf77f7148c04722977f72537314))
* **event:** track event trigger times ([46997de](https://github.com/folke/lazy.nvim/commit/46997de1c90620897e2a7f31bd9e4751c1223d21))
* **help:** accept patterns for readme ([#269](https://github.com/folke/lazy.nvim/issues/269)) ([d521a25](https://github.com/folke/lazy.nvim/commit/d521a25cfc8608057eade67bfe7991f1ce1ed1b9))
* **loader:** incrementally install missing plugins and rebuild spec, so imported specs from plugins work as expected ([2d06faa](https://github.com/folke/lazy.nvim/commit/2d06faa941998f76f0348b7b69c5ecdcb5f3db2a))
* **spec:** added `import` to import other plugin modules ([919b7f5](https://github.com/folke/lazy.nvim/commit/919b7f5de3ba78d2030be617b64ada17bddd47da))
* **spec:** added support for importing multiple spec modules with `import = "foobar"` ([39b6602](https://github.com/folke/lazy.nvim/commit/39b66027a5c5db9ba6f3a7253cc6513882c27f2a))
* **spec:** allow mergig of config, priority and dependencies ([313015f](https://github.com/folke/lazy.nvim/commit/313015fdb4b44a38f4b5c9fd045c5d29a65f7c7a))
* **spec:** show spec warnings in checkhealth only ([bc4133c](https://github.com/folke/lazy.nvim/commit/bc4133cb3e2d3dceed11d416ab1a0ece2d37f759))
* **ui:** show new version that is available instead of general message ([34e2c78](https://github.com/folke/lazy.nvim/commit/34e2c78e0690a93196b5e59bbc9e050dfd6f3986))
* **ui:** when updating to a new version, show the version instead of the commit refs ([0fadb5e](https://github.com/folke/lazy.nvim/commit/0fadb5e1cec709de839ecd6937b338b9201734ad))
* **util:** added trackfn that wraps a function and tracks timings ([50a456c](https://github.com/folke/lazy.nvim/commit/50a456c189a6ea68f7681c95fe5cfa9c968e4fc6))


### Bug Fixes

* **cache:** allow lazyvim as a plugin ([f6b0172](https://github.com/folke/lazy.nvim/commit/f6b0172e92c502bd4b1482cbb8bed4e6e3231357))
* **cache:** autoloading was broken! ([9e90852](https://github.com/folke/lazy.nvim/commit/9e90852a471205e92e524e9052cc2df101a24d80))
* **cache:** dont return directories in lsmod ([9893430](https://github.com/folke/lazy.nvim/commit/9893430187d70f69aed552e286223671e8ece72f))
* **cache:** keep ordering of topmods the same as in rtp ([11eee43](https://github.com/folke/lazy.nvim/commit/11eee43c7ee63a71b08009769437e8a10814a48c))
* **cache:** only autoload when plugins have been parsed. Needed to support `import` ([0bc73db](https://github.com/folke/lazy.nvim/commit/0bc73db503e550076c0a8effb976a778c7cf5a6a))
* **cache:** properly return two values for finddir ([1ec8f08](https://github.com/folke/lazy.nvim/commit/1ec8f08480493ea1faffebcd3c89ce9e65732054))
* **commands:** fixed plugin completion for commands ([205ce42](https://github.com/folke/lazy.nvim/commit/205ce42cdc93bc62b1c2ae1c754180c5a23be8de))
* **fetch:** always fetch latest origin tags. Fixes [#264](https://github.com/folke/lazy.nvim/issues/264) ([a9de591](https://github.com/folke/lazy.nvim/commit/a9de5910f22faf9036a8297c8fd4e3d47eb8baa6))
* **handler:** properly show errors generated by setting up handlers ([4d77cf2](https://github.com/folke/lazy.nvim/commit/4d77cf2efea3ddec1bc2a335f90bf3a1cfe19db2))
* **health:** always use main spec ([6ff480b](https://github.com/folke/lazy.nvim/commit/6ff480bdee276265e69f644877706ccb11892799))
* **help:** properly escape helptags search pattern ([#268](https://github.com/folke/lazy.nvim/issues/268)) ([1edd1b8](https://github.com/folke/lazy.nvim/commit/1edd1b8945ee91cdfd61654af96c427dce285a9d))
* **loader:** always load init.lua in plugin mods ([60e96b4](https://github.com/folke/lazy.nvim/commit/60e96b478a5374ad1829a505549e3170332d1013))
* **loader:** setup handlers after installing missing plugins. Fixes [#272](https://github.com/folke/lazy.nvim/issues/272) ([b23a5dc](https://github.com/folke/lazy.nvim/commit/b23a5dc8d5d873e3c53283a376c9d9b5ee33697f))
* **plugin:** only get plugin from spec when needed. ([ce3e1fc](https://github.com/folke/lazy.nvim/commit/ce3e1fc5603b9f81165f331350bd2dd54b000d32))
* **spec:** allow a spec module to be on the rtp and not only in config ([51c23b6](https://github.com/folke/lazy.nvim/commit/51c23b661e695d3998893bfd71de2646a6190ad4))
* **spec:** normalize deps before adding spec to make sure merging works as expected ([7d75598](https://github.com/folke/lazy.nvim/commit/7d755987ba6ea6ef8a3213f2119c5e31810ac913))


### Performance Improvements

* **cache:** cache all lua files till UIEnter instead of VimEnter ([77ff7be](https://github.com/folke/lazy.nvim/commit/77ff7beaa49769961b01b4d5b9099b4536ba1de4))
* track some additional cputimes ([d992387](https://github.com/folke/lazy.nvim/commit/d99238791289e7ee5bd847fd10ac3a93ab3422e6))

## [7.8.0](https://github.com/folke/lazy.nvim/compare/v7.7.0...v7.8.0) (2022-12-31)


### Features

* **ui:** press `&lt;c-c&gt;` to abort any running tasks. Fixes [#258](https://github.com/folke/lazy.nvim/issues/258) ([d6b5d6e](https://github.com/folke/lazy.nvim/commit/d6b5d6e756a596304fd4acbc46f9fa553ea880a2))


### Bug Fixes

* **util:** remove double forward slashes ([ed0583e](https://github.com/folke/lazy.nvim/commit/ed0583e82b2797944889aa2c08bb440e6da9f16b))

## [7.7.0](https://github.com/folke/lazy.nvim/compare/v7.6.0...v7.7.0) (2022-12-31)


### Features

* **git:** added support for packed-refs. Fixes [#260](https://github.com/folke/lazy.nvim/issues/260) ([865ff41](https://github.com/folke/lazy.nvim/commit/865ff414c70d20648000d1b9d754dba64dbf4a62))
* **ui:** make brower configurable. Fixes [#248](https://github.com/folke/lazy.nvim/issues/248) ([679d85c](https://github.com/folke/lazy.nvim/commit/679d85c9ffb6bd49d27267b3a282eeb73e063cde))
* **ui:** show when plugin would be loaded for unloaded plugins. Fixes [#261](https://github.com/folke/lazy.nvim/issues/261) ([5575d2b](https://github.com/folke/lazy.nvim/commit/5575d2b2a9eb7e104d85f4f68754ef3734c7a4a1))


### Bug Fixes

* **bootstrap:** fixed bootstrap script ([de82a99](https://github.com/folke/lazy.nvim/commit/de82a991971d20cfaaeb0d86802283e2ac4a4574))
* duplicate state check in bootstrap ([#255](https://github.com/folke/lazy.nvim/issues/255)) ([51fb95e](https://github.com/folke/lazy.nvim/commit/51fb95e4a89743670eb2ba710bcdb0e91834c3d4))
* **git:** always get both tag and version ([cb29427](https://github.com/folke/lazy.nvim/commit/cb29427926121922eb6cc669d22897f7bc9687f1))
* **keys:** forward `count` to keymaps. Fixes [#252](https://github.com/folke/lazy.nvim/issues/252) ([a834b30](https://github.com/folke/lazy.nvim/commit/a834b30c70581e505d8dd62d9c6f9de6a6eba868))
* **ui:** only show plugins to clean under clean ([45d669f](https://github.com/folke/lazy.nvim/commit/45d669f61c8fc239712e794e1e2c5af1f737ee0a))


### Performance Improvements

* **loader:** re-use topmod cache to find `setup()` module ([730bb84](https://github.com/folke/lazy.nvim/commit/730bb84364afee156ad1dde03fc30de3d96af63a))

## [7.6.0](https://github.com/folke/lazy.nvim/compare/v7.5.0...v7.6.0) (2022-12-30)


### Features

* **api:** allow passing options to float so it can be used outside of lazy ([2a617a7](https://github.com/folke/lazy.nvim/commit/2a617a7024d2ed99ff9b51e36600b9c56d928bfc))
* **commands:** added health command to run `:checkhealth lazy` ([86dff1b](https://github.com/folke/lazy.nvim/commit/86dff1b59a978c9db8768e88f07c0532f65f3c8d))
* **health:** added spec parsing errors to `:checkhealth` ([32511a1](https://github.com/folke/lazy.nvim/commit/32511a121407aab44a839c68592860856c691f9f))
* **restore:** you can now restore a plugin to a certain commit. Fixes [#234](https://github.com/folke/lazy.nvim/issues/234) ([1283c2b](https://github.com/folke/lazy.nvim/commit/1283c2b28826c37cb12e5e28d0988f9b8848293e))
* **startup:** missing plugins will now install the versions in the lockfile if available. Fixes [#138](https://github.com/folke/lazy.nvim/issues/138) ([81ee02b](https://github.com/folke/lazy.nvim/commit/81ee02b8f69be2eabd670b8bcc423dba590821de))


### Bug Fixes

* **cache:** clear cached entry on errors ([def5cc5](https://github.com/folke/lazy.nvim/commit/def5cc58166e914bce0a20ed60e0c8be99e76eb4))

## [7.5.0](https://github.com/folke/lazy.nvim/compare/v7.4.2...v7.5.0) (2022-12-29)


### Features

* **bootstrap:** bootstrap with last lazy stable release ([929198b](https://github.com/folke/lazy.nvim/commit/929198bc4feca8089ff265a977854501e3f25c66))

## [7.4.2](https://github.com/folke/lazy.nvim/compare/v7.4.1...v7.4.2) (2022-12-29)


### Bug Fixes

* **loader:** normalize rtp paths on windows [#230](https://github.com/folke/lazy.nvim/issues/230) ([a4bd4dc](https://github.com/folke/lazy.nvim/commit/a4bd4dc4a7b688b6f68f483bd04b85bb83a96bd8))

## [7.4.1](https://github.com/folke/lazy.nvim/compare/v7.4.0...v7.4.1) (2022-12-29)


### Bug Fixes

* **ftdetect:** source ftdetect files only once. Fixes [#235](https://github.com/folke/lazy.nvim/issues/235) ([9f3fb38](https://github.com/folke/lazy.nvim/commit/9f3fb3840228a4d812197f7c6dbd08a9c60d85af))

## [7.4.0](https://github.com/folke/lazy.nvim/compare/v7.3.0...v7.4.0) (2022-12-29)


### Features

* **cache:** update package.loaded on require ([021e546](https://github.com/folke/lazy.nvim/commit/021e54655f8ba9c594b2035f044e5a2a1b13a893))
* **plugin:** allow some `lazy.nvim` spec props to be set by the user ([c8553ca](https://github.com/folke/lazy.nvim/commit/c8553ca44fefb934ebedb1fabba3ca492848fccc))
* **profile:** nicer threshold prompt ([#210](https://github.com/folke/lazy.nvim/issues/210)) ([ff8f378](https://github.com/folke/lazy.nvim/commit/ff8f3783fa5dabdb086c5731c46d1a4cf79917af))
* **ui:** added extra cache stats to the debug tab ([c2f7e2d](https://github.com/folke/lazy.nvim/commit/c2f7e2d0981ec5f06a73923296cfbe52c69ab5da))


### Bug Fixes

* **cache:** ad jit.verion to cache version string. Fixes [#225](https://github.com/folke/lazy.nvim/issues/225) ([e3ffcff](https://github.com/folke/lazy.nvim/commit/e3ffcff7cce1206a2e41b413b0923a3aafeb9306))
* **cache:** added support for top level lua linked directories. Fixes [#233](https://github.com/folke/lazy.nvim/issues/233) ([853d4d5](https://github.com/folke/lazy.nvim/commit/853d4d58381870a4804ee7d822d3331d3cc5924d))
* **cache:** always normalize modname separators ([8544c38](https://github.com/folke/lazy.nvim/commit/8544c389ab54dd21c562b2763829670c71266caa))
* **cache:** check package.loaded after auto-load and return existing module if present. Fixes [#224](https://github.com/folke/lazy.nvim/issues/224) ([044e28b](https://github.com/folke/lazy.nvim/commit/044e28bf8bb454335c63998ef6f21bc34b3e6124))
* **cache:** dont update rtp in fast events ([4b75d06](https://github.com/folke/lazy.nvim/commit/4b75d06c076745379fb1688d2bd00eeabeaa4a4b))
* **cache:** make it work again... #fixup ([370b1b9](https://github.com/folke/lazy.nvim/commit/370b1b982e95c004512604eb87f0facd03340095))
* **cache:** OptionSet is not triggered during startup, so use #rtp instead to see if it changed ([9997523](https://github.com/folke/lazy.nvim/commit/9997523841bd39c90d785807411b6babc529f366))
* **cache:** properly get rtp during fast events ([95b9cf7](https://github.com/folke/lazy.nvim/commit/95b9cf743c4d6aab879c2259b79346c6f306dab8))
* **cache:** reload file if compiled code is incompatible. Fixes [#225](https://github.com/folke/lazy.nvim/issues/225) ([b8c5ab5](https://github.com/folke/lazy.nvim/commit/b8c5ab5dae0b826e576a9a99f92a7e63fb20fb01))
* **cmd:** fixed signature of cmd._del. Fixes [#229](https://github.com/folke/lazy.nvim/issues/229) ([a2eac68](https://github.com/folke/lazy.nvim/commit/a2eac685754252c903094aefa40ab6d747d103aa))
* **commands:** E5108 in getcompletions ([#207](https://github.com/folke/lazy.nvim/issues/207)) ([acd6697](https://github.com/folke/lazy.nvim/commit/acd6697d8810e501d3861bba2ac45d5f4555c43a))
* **config:** reset packpath to include VIMRUNTIME only. Fixes [#214](https://github.com/folke/lazy.nvim/issues/214) ([db043da](https://github.com/folke/lazy.nvim/commit/db043da829899239399ef04e917a95c4ceb9b8e6))
* **ft:** only trigger filetypepluing and filetypeindent for ft handler. Fixes [#228](https://github.com/folke/lazy.nvim/issues/228) ([7de662d](https://github.com/folke/lazy.nvim/commit/7de662d037a96fccc3e3d784468b01794288a7b6))
* **git:** add --no-show-signature. Fixes [#218](https://github.com/folke/lazy.nvim/issues/218) ([6c0b803](https://github.com/folke/lazy.nvim/commit/6c0b8039990b08b46b5d0c69392256e9f3a2f8d8))
* **health:** add `cond` key ([#203](https://github.com/folke/lazy.nvim/issues/203)) ([b813fae](https://github.com/folke/lazy.nvim/commit/b813fae61cebbc5b45e7ea3bfbe214b0d5769696))
* **health:** add new key `priority` to `:checkhealth lazy` ([#196](https://github.com/folke/lazy.nvim/issues/196)) ([dc03fa1](https://github.com/folke/lazy.nvim/commit/dc03fa1ae57c3949874c9cae50074a83232c4eed))
* **loader:** implemented correct adding to rtp. fix [#230](https://github.com/folke/lazy.nvim/issues/230), fix [#226](https://github.com/folke/lazy.nvim/issues/226) ([3a1a10c](https://github.com/folke/lazy.nvim/commit/3a1a10cd75b47f2aae1f843286cc17d8a780dff1))
* **loader:** show proper error message when trying to load a plugin that is not installed. Fixes [#201](https://github.com/folke/lazy.nvim/issues/201). Fixes [#202](https://github.com/folke/lazy.nvim/issues/202) ([956164d](https://github.com/folke/lazy.nvim/commit/956164d27dc02b8d3c21c9ef7cc9028d854b0978))
* **loader:** temporary fix for Vimtex and others. See [#230](https://github.com/folke/lazy.nvim/issues/230) ([c7122d6](https://github.com/folke/lazy.nvim/commit/c7122d64cdf16766433588486adcee67571de6d0))
* **loader:** when `config=true`, pass `nil` to `setup()`. Fixes [#208](https://github.com/folke/lazy.nvim/issues/208) ([5f423b2](https://github.com/folke/lazy.nvim/commit/5f423b29c65f536a9c41a34a8328372baa444da5))
* only show fired ft events in debug obvioulsy. Fixes [#232](https://github.com/folke/lazy.nvim/issues/232) ([c7c1295](https://github.com/folke/lazy.nvim/commit/c7c1295c3e429d4a95e36b5c5b2dfcbeca61f42d))
* **rtp:** correct order of adding to rtp. Fixes [#226](https://github.com/folke/lazy.nvim/issues/226) ([4e3a973](https://github.com/folke/lazy.nvim/commit/4e3a973f85bd2393009d495ecfd6c058345309d4))


### Performance Improvements

* move autoloader to cache and always use lazy's modname path resolver which is much faster ([34977c2](https://github.com/folke/lazy.nvim/commit/34977c2b80db3ce5054f3925057b6b8ccbd7ce7e))

## [7.3.0](https://github.com/folke/lazy.nvim/compare/v7.2.0...v7.3.0) (2022-12-27)


### Features

* **plugin:** added `Plugin.priority` for start plugins ([edf8310](https://github.com/folke/lazy.nvim/commit/edf8310288197d4f7c2983a4fa32c09921f00a22))
* **profile:** added accurate startuptime to ui/stats/docs ([a2fdf36](https://github.com/folke/lazy.nvim/commit/a2fdf369f2d503ebe44b421b821c9430c8d5cbe1))
* **reloader:** trigger LazyReload when changes were detected and after reload. Fixes [#178](https://github.com/folke/lazy.nvim/issues/178) ([4e4493b](https://github.com/folke/lazy.nvim/commit/4e4493b21d6b55742b00babd166dc1c1acbfa4ba))
* **ui:** added new section specifically for updates ([3b46160](https://github.com/folke/lazy.nvim/commit/3b46160c01c4b205aa6665096b263663bd433acd))
* **util:** use treesitter to highlight notify messages when available ([d1739cb](https://github.com/folke/lazy.nvim/commit/d1739cb7e1791e90d015610ef4aad30803babddb))


### Bug Fixes

* **cache:** never use packer paths from cache ([bb53b84](https://github.com/folke/lazy.nvim/commit/bb53b8473cd065dc467853222ee3462739ab16fa))
* **ft:** always trigger FileType when lazy-loading on ft ([5618076](https://github.com/folke/lazy.nvim/commit/5618076a451232184b3ed2572ec85573896f48d4))
* **plugin:** find plugins with `/lua/` instead of `/lua` ([8a3152d](https://github.com/folke/lazy.nvim/commit/8a3152de9357cf751546da5a17b9fd52868344f1))
* **plugin:** pass plugin as arg to config/init/build ([b6ebed5](https://github.com/folke/lazy.nvim/commit/b6ebed5888309dd5d9eda145c403627826fd6a35))
* **reloader:** remove extra trailing separator ([#180](https://github.com/folke/lazy.nvim/issues/180)) ([c4d924a](https://github.com/folke/lazy.nvim/commit/c4d924aceea13cfab5cf23d0765c5d206deff341))
* **ui:** removed newlines from profile tab ([0d0d11a](https://github.com/folke/lazy.nvim/commit/0d0d11acb2547ea65e0eba4fb6855f0954ed0239))

## [7.2.0](https://github.com/folke/lazy.nvim/compare/v7.1.0...v7.2.0) (2022-12-26)


### Features

* **cache:** make ttl configurable ([4aa362e](https://github.com/folke/lazy.nvim/commit/4aa362e8dc9ddf1e745085dc242c814569fcce37))
* **plugin:** added `Plugin.cond`. Fixes [#89](https://github.com/folke/lazy.nvim/issues/89), [#168](https://github.com/folke/lazy.nvim/issues/168) ([aed842a](https://github.com/folke/lazy.nvim/commit/aed842ae1e39aa227069a7f46ef0e141efbd021b))
* **ui:** made all highlight groups and icons configurable ([0ea771b](https://github.com/folke/lazy.nvim/commit/0ea771bd70feaba8002e129ef16f65b1dff7c392))
* **ui:** make lazy icon configurable ([#163](https://github.com/folke/lazy.nvim/issues/163)) ([8ea9d8b](https://github.com/folke/lazy.nvim/commit/8ea9d8b0241f2b09b65355039ec89446bde94564))
* **ui:** re-render after resize. Fixes [#174](https://github.com/folke/lazy.nvim/issues/174) ([9a2ecc8](https://github.com/folke/lazy.nvim/commit/9a2ecc875003a4cbcfba2eeaea0fbd794d270449))


### Bug Fixes

* **diff:** use git show when only displaying one commit ([#155](https://github.com/folke/lazy.nvim/issues/155)) ([037f242](https://github.com/folke/lazy.nvim/commit/037f2424303118b1a8312ed31081f518735823d5))
* **keys:** don't escape pendig keys twice and only convert when number ([46280a1](https://github.com/folke/lazy.nvim/commit/46280a191bd1b6b30607f0d97e1c6d1bcbab1a93))
* **keys:** only delete key handler mappings once ([9837d5b](https://github.com/folke/lazy.nvim/commit/9837d5be7e5fe3aed173401f469d371f26c334c7))
* **loader:** add proper error message when trying to load a plugin that doesn't exist. Fixes [#160](https://github.com/folke/lazy.nvim/issues/160) ([9095223](https://github.com/folke/lazy.nvim/commit/90952239d24a9c3496bc2ecf7da1624e6e05d37e))
* **ui:** get plugin details from the correct plugin in case it was deleted ([2f5c1be](https://github.com/folke/lazy.nvim/commit/2f5c1be5255a318d610e0a86abe0a38bf18af4ad))

## [7.1.0](https://github.com/folke/lazy.nvim/compare/v7.0.0...v7.1.0) (2022-12-24)


### Features

* **build:** build can now be a list to execute multiple build commands. Fixes [#143](https://github.com/folke/lazy.nvim/issues/143) ([9110371](https://github.com/folke/lazy.nvim/commit/9110371120db2888647123d7dea7c68a574ae310))
* **manage:** added user events when operations finish. Fixes [#135](https://github.com/folke/lazy.nvim/issues/135) ([a36d506](https://github.com/folke/lazy.nvim/commit/a36d50639358bc00b8ac2d42a8a0a6c0f9c08310))
* **ui:** added custom commands for lazygit and opening a terminal for a plugin ([be3909c](https://github.com/folke/lazy.nvim/commit/be3909c54420c734e32cb045a387990a6fb51bd4))
* **ui:** added multiple options for diff command ([7d02da2](https://github.com/folke/lazy.nvim/commit/7d02da2ff0216ef6ba9097d8ae5a48f54ddc7c4a))
* **ui:** you can now hover over a plugin to open a diff of updates or the plugin homepage ([593d6e4](https://github.com/folke/lazy.nvim/commit/593d6e400b3bb529c507092bf107b6cc4364fb5b))
* util method to open a float ([7c2eb15](https://github.com/folke/lazy.nvim/commit/7c2eb1544416646db09b410d07492555fcf44778))
* **util:** open terminal commands in a float ([8ad05fe](https://github.com/folke/lazy.nvim/commit/8ad05feef19d6b8d4c5f686e0269ac10659f511b))


### Bug Fixes

* **checker:** update updated after every manage operation. Fixes [#141](https://github.com/folke/lazy.nvim/issues/141) ([86f2c67](https://github.com/folke/lazy.nvim/commit/86f2c67aa80b3c64d131ba47189c42ca5a37ac14))
* **help:** make sure we always generate lazy helptags ([f360e33](https://github.com/folke/lazy.nvim/commit/f360e336a5e2b57e1ee0232c9c89a4ceb3617798))
* **manage:** only clear plugins for the op instead of all ([fc182f7](https://github.com/folke/lazy.nvim/commit/fc182f7c5d5df9ba877ab619f6fa545e20ad52f0))
* plugin list can be string[]. Fixes [#145](https://github.com/folke/lazy.nvim/issues/145) ([74d8b8e](https://github.com/folke/lazy.nvim/commit/74d8b8e4e180c40d2ade750940f3c64761fb7930))

## [7.0.0](https://github.com/folke/lazy.nvim/compare/v6.0.0...v7.0.0) (2022-12-23)


### ⚠ BREAKING CHANGES

* default lazy cache path is now under cache instead of state
* `init()` no longer implies lazy-loading. Add `lazy=false` for affected plugins
* run `init()` before loading start plugins. Fixes #107

### Features

* `init()` no longer implies lazy-loading. Add `lazy=false` for affected plugins ([8112640](https://github.com/folke/lazy.nvim/commit/81126403a89b78e6a75948ba5cea15d9499d2025))
* **loader:** automatically lazy-load colorschemes ([07b4677](https://github.com/folke/lazy.nvim/commit/07b467738d3ca0863e957a2bca86825f6aff92df))
* **spec:** `config` can be `true` or a `table` that will be passed to `require("plugin").setup(config)` ([2a7b004](https://github.com/folke/lazy.nvim/commit/2a7b0047dd25f543b147b692fe100e1b2d88ffb2))
* **spec:** allow using plugin names in dependencies ([4bf771a](https://github.com/folke/lazy.nvim/commit/4bf771a6b255fd91b2e16a21da20d55f7f274f05))
* **ui:** added options to sort/filter profiling data ([7dfb9c1](https://github.com/folke/lazy.nvim/commit/7dfb9c1f5cb8dcad4133a93da68cbdb5c8001035))


### Bug Fixes

* added error message to debug failing extmarks [#117](https://github.com/folke/lazy.nvim/issues/117) ([65e9036](https://github.com/folke/lazy.nvim/commit/65e903652bfac5e83d4df8246a29e45c07865c34))
* **checker:** dont report updates on install during startup ([8251c23](https://github.com/folke/lazy.nvim/commit/8251c23c90c15ef5197638777f85ef69402a2725))
* **install:** make sure to setup loaders before attempting install so colorscheme can load. Fixes [#122](https://github.com/folke/lazy.nvim/issues/122) ([7b9b476](https://github.com/folke/lazy.nvim/commit/7b9b476a6238a53062c1c8e4331fcef054bb8761))
* **keys:** don't create with remap! ([b440b3a](https://github.com/folke/lazy.nvim/commit/b440b3ac2d6945fab62fbfc2f2dbe9db3d9d9fe2))
* **keys:** dont delete handlers manually. Let loader do that ([72b3899](https://github.com/folke/lazy.nvim/commit/72b38999bc547a96c769d1de964a846570cfe5d1))
* **keys:** key handlers were not working after reload ([3f60f2d](https://github.com/folke/lazy.nvim/commit/3f60f2dc13faf4d958fdaec16596436ade2ec23d))
* **manage:** do not reload pugins on clear ([b5d6afc](https://github.com/folke/lazy.nvim/commit/b5d6afc4fa4520a986db4898f6b22b267fc041f9))
* pass plugins instead of plugin names to command. Fixes [#103](https://github.com/folke/lazy.nvim/issues/103) ([42f5aa7](https://github.com/folke/lazy.nvim/commit/42f5aa76e21ec34b3d7fc79218e5069610d7db2e))
* remove debug print ([08d458c](https://github.com/folke/lazy.nvim/commit/08d458c5ba595c3ae2801215abf2d5cc09aca211))
* remove lazy keymaps with the correct mode. Fixes [#97](https://github.com/folke/lazy.nvim/issues/97) ([56890ce](https://github.com/folke/lazy.nvim/commit/56890ce5f439e9bbf275ed5ec2573b4e29371bb5))
* run `init()` before loading start plugins. Fixes [#107](https://github.com/folke/lazy.nvim/issues/107) ([2756a6f](https://github.com/folke/lazy.nvim/commit/2756a6f756758d62eeb4cac64d8c5efbc8878cd1))
* **ui:** fix buffer being properly deleted ([#112](https://github.com/folke/lazy.nvim/issues/112)) ([9e98389](https://github.com/folke/lazy.nvim/commit/9e983898b131d4975680bbda023224bb90a32daf))
* **ui:** fixed extmarks while wrapping. Fixes [#124](https://github.com/folke/lazy.nvim/issues/124) ([e973323](https://github.com/folke/lazy.nvim/commit/e973323e95d9cd9ebf41583c94a8c7433d5ae19c))
* **ui:** sort profiling chronological by default ([50e3b91](https://github.com/folke/lazy.nvim/commit/50e3b917675b8bd693548089aeda7e9cbe881001))


### Code Refactoring

* default lazy cache path is now under cache instead of state ([cc6276e](https://github.com/folke/lazy.nvim/commit/cc6276e9b069b5c0c3bdef27dd029722b13bf17d))

## [6.0.0](https://github.com/folke/lazy.nvim/compare/v5.2.0...v6.0.0) (2022-12-22)


### ⚠ BREAKING CHANGES

* lazy api commands now take an opts table instead of a list of plugins

### Features

* added support for `nvim --headless "+Lazy! sync" +qa` ([2e14a2f](https://github.com/folke/lazy.nvim/commit/2e14a2f3243e2979e00405fe417bc530bf1e8ca3))
* **checker:** defer checker to after VeryLazy to make sure nvim-notify and others are loaded ([fd1fbef](https://github.com/folke/lazy.nvim/commit/fd1fbefc3df2b8e92209ed932144edc49877c41e))
* **keys:** more advanced options for setting lazy key mappings ([1c07ea1](https://github.com/folke/lazy.nvim/commit/1c07ea15a37442b7d07dcce9791c497c343ee853))
* lazy api commands now take an opts table instead of a list of plugins ([bc61747](https://github.com/folke/lazy.nvim/commit/bc617474a0bbd9a2e8ec68fd97e09c1682be7ff9))
* **ui:** show modpaths in debug ([6304231](https://github.com/folke/lazy.nvim/commit/63042310f4eaae19ff8a46dfd2ef931c1f498b0f))


### Bug Fixes

* **cache:** overwrite cache entry with new modpath when loading a file. Fixes [#90](https://github.com/folke/lazy.nvim/issues/90) ([2200284](https://github.com/folke/lazy.nvim/commit/22002841653574d57cef7a3137303a25da0796f6))
* **clean:** update lockfile on clean ([#88](https://github.com/folke/lazy.nvim/issues/88)) ([dd9648f](https://github.com/folke/lazy.nvim/commit/dd9648f8ec6526ac376f3ffa85062f6a21385f4d))
* **cmd:** allow ranges. Fixes [#93](https://github.com/folke/lazy.nvim/issues/93) ([c0c2e1b](https://github.com/folke/lazy.nvim/commit/c0c2e1bd68b48610cdca1d3e6a540fd68fc36527))
* **git:** make sure we properly fetch git submodules. Fixes [#72](https://github.com/folke/lazy.nvim/issues/72) ([7f6f31d](https://github.com/folke/lazy.nvim/commit/7f6f31d66f2aba99fad86a64789b7d5d3e61a2cb))
* **git:** remove --also-filter-submodules. Fixes [#86](https://github.com/folke/lazy.nvim/issues/86) [#83](https://github.com/folke/lazy.nvim/issues/83) ([488b487](https://github.com/folke/lazy.nvim/commit/488b48779c1ee6fb4a0d69e31a6c58784cceb403))
* **install:** update lockfile also on install ([4cf176b](https://github.com/folke/lazy.nvim/commit/4cf176bdabbd1a18a20b3b4a608175fb1ba3250e))
* removed spell again from site. not needed. can download in config/spell ([58f0876](https://github.com/folke/lazy.nvim/commit/58f0876e81881c487ea10e393fa828a1c45c74f4))
* **rtp:** keep site in rtp ([94d0125](https://github.com/folke/lazy.nvim/commit/94d012511d19a4438c0098fff000a6d63198f2c8))
* show mapleader warning with vim.schedule. Fixes [#91](https://github.com/folke/lazy.nvim/issues/91) ([28f1511](https://github.com/folke/lazy.nvim/commit/28f1511e0a19d41f9c5e53a64ece257449681b4d))

## [5.2.0](https://github.com/folke/lazy.nvim/compare/v5.1.0...v5.2.0) (2022-12-21)


### Features

* **loader:** allow to add extra paths to rtp reset. Fixes [#64](https://github.com/folke/lazy.nvim/issues/64) ([876f7bd](https://github.com/folke/lazy.nvim/commit/876f7bd47124b4b2881917b36c5d29f3a898eab5))
* **loader:** warn when mapleader is changed after init ([4ca3039](https://github.com/folke/lazy.nvim/commit/4ca30390ec4149763169201b651ad9e78c56896f))
* make hover easy to override ([f0e1b85](https://github.com/folke/lazy.nvim/commit/f0e1b853a0d0d34584ecf9ecbf6ef8599db8b5c2))
* **plugin:** allow plugin files only without a main plugin module. Fixes [#53](https://github.com/folke/lazy.nvim/issues/53) ([44f80a7](https://github.com/folke/lazy.nvim/commit/44f80a7f5d80a56dbfcc5cda34cc805a78ac7189))
* **util:** utility method to get sync process output ([e95da35](https://github.com/folke/lazy.nvim/commit/e95da35d09989d15122ec4bb1364d9c36e36317d))


### Bug Fixes

* **cache:** if we can't load from the cache modpath, find path again instead of erroring right away ([a345649](https://github.com/folke/lazy.nvim/commit/a345649510aad552c0dab4e7a666d387b4ea22d3))
* **checker:** allow git checks only for non-pinned plugins ([#61](https://github.com/folke/lazy.nvim/issues/61)) ([a939243](https://github.com/folke/lazy.nvim/commit/a939243639d452ef5f50fd8f87b8659862f16d37))
* **git:** dereference tag refs. Fixes [#54](https://github.com/folke/lazy.nvim/issues/54) ([86eaa11](https://github.com/folke/lazy.nvim/commit/86eaa118c6d6b5c2806c38aac8db664ba6d780f6))
* **git:** only mark a plugin as dirty if an update changed the commit HEAD. Fixes [#62](https://github.com/folke/lazy.nvim/issues/62) ([bbace14](https://github.com/folke/lazy.nvim/commit/bbace14dc96cd2379aa3f49446ba35a1ad5bfdfa))
* **health:** don't show warning on `module=false` ([c228908](https://github.com/folke/lazy.nvim/commit/c228908ffc485ee01a5ac118e23e13ce3d19cbf9))
* **help:** sort tags files for readmes so tags work properly. Fixes [#67](https://github.com/folke/lazy.nvim/issues/67) ([2fd78fb](https://github.com/folke/lazy.nvim/commit/2fd78fbed8d22524af83a78558dbc895df15d58d))
* **keys:** feedkeys should include pending keys. Fixes [#71](https://github.com/folke/lazy.nvim/issues/71) ([2ab6518](https://github.com/folke/lazy.nvim/commit/2ab651864f30022751252e66b4cd2c1e36800d06))
* **loader:** lua modules can be links instead of files. Fixes [#66](https://github.com/folke/lazy.nvim/issues/66) ([b7c489b](https://github.com/folke/lazy.nvim/commit/b7c489b08f79765b7c840addc4e542b875438f47))
* **loader:** source rtp `/plugin` files after loading start plugins. Fixes ([ff24f49](https://github.com/folke/lazy.nvim/commit/ff24f493ee053f25fc8b34b74443a9f000fdbd55))
* strip `/` from dirs. Fixes [#60](https://github.com/folke/lazy.nvim/issues/60) ([540847b](https://github.com/folke/lazy.nvim/commit/540847b7cb4afc66fea0d7a539821431c5a2b216))
* **ui:** install command can have plugins as a parameter ([232232d](https://github.com/folke/lazy.nvim/commit/232232da5a2d012da0da27b424a016379c83c2f9))
* **ui:** set current win only when its valid ([3814883](https://github.com/folke/lazy.nvim/commit/3814883aaae3facc931087bfa7352ca18fa658ac))

## [5.1.0](https://github.com/folke/lazy.nvim/compare/v5.0.1...v5.1.0) (2022-12-20)


### Features

* added options to configure change detection. Fixes [#32](https://github.com/folke/lazy.nvim/issues/32) ([6c767a6](https://github.com/folke/lazy.nvim/commit/6c767a604de025c0d03c4e2b65f6c4a01ec4918d))
* **ui:** make the windoww size configurable. Fixes [#34](https://github.com/folke/lazy.nvim/issues/34) ([941df31](https://github.com/folke/lazy.nvim/commit/941df31a41560b4131260c47c482bd12502ed8c5))


### Bug Fixes

* add filetype to window buffer. ([#41](https://github.com/folke/lazy.nvim/issues/41)) ([897d6df](https://github.com/folke/lazy.nvim/commit/897d6df5ac8d0e575d52eec60722ce9ffc80cf6f))
* **git:** don't run git log for submodules. Fixes [#33](https://github.com/folke/lazy.nvim/issues/33) ([9d12cdc](https://github.com/folke/lazy.nvim/commit/9d12cdcc0624c8a7f3c7c89f87abf992bc6c217e))
* **loader:** source filetype.lua before plugins. Fixes [#35](https://github.com/folke/lazy.nvim/issues/35) ([ffcd0ab](https://github.com/folke/lazy.nvim/commit/ffcd0ab7bb61bd15b24d2a47509861e30644143c))
* **spec:** only process a spec once ([b193f96](https://github.com/folke/lazy.nvim/commit/b193f96f7b71026f80fd89b6c3fc55fe982bbd1a))
* use nvim_feekeys instead of nvim_input for keys handler. Fixes [#28](https://github.com/folke/lazy.nvim/issues/28) ([5298441](https://github.com/folke/lazy.nvim/commit/52984419ffa051d66bccec9f93e7cbb4fdd94976))


### Performance Improvements

* **ui:** clear existing extmarks before rendering ([06ac8bd](https://github.com/folke/lazy.nvim/commit/06ac8bda66caccca08a18ddac7d25526dff45bb6))

## [5.0.1](https://github.com/folke/lazy.nvim/compare/v5.0.0...v5.0.1) (2022-12-20)


### Bug Fixes

* add neovim libs to rtp for treesitter parsers etc ([df6c986](https://github.com/folke/lazy.nvim/commit/df6c9863dc05b309db9739b05bfabff55f08bf62))
* always set Config.me regardless of reset rtp ([992c679](https://github.com/folke/lazy.nvim/commit/992c6791ef1f9f75b9f20833903bc3a9e43dce90))
* **build:** use the shell to execute build commands ([1371a14](https://github.com/folke/lazy.nvim/commit/1371a141677afe2b0d0d66c96e15ed3ba271bbd9))
* **cache:** if mod is loaded already in the loader, then return that ([ffabe91](https://github.com/folke/lazy.nvim/commit/ffabe91b2d72d686fb21d3159e20bf8faab7ed24))
* checker should not error on non-existing dirs ([ddf36d7](https://github.com/folke/lazy.nvim/commit/ddf36d77486ee80fb8358da88411b28e479d9b0a))
* deepcopy lazyspec before processing ([6e32759](https://github.com/folke/lazy.nvim/commit/6e32759c5ddc43d7095793de952fa2c62f61cb22))
* default logs are now since 3 days ago to be in line with the docs ([e9d3a73](https://github.com/folke/lazy.nvim/commit/e9d3a73bbceaac0dafacd6a3c6c76ab37799d15b))
* dont autoload cached modules when module=false ([316503f](https://github.com/folke/lazy.nvim/commit/316503f124eb4caf5b3bac0da16ee6ac10322424))
* move re-sourcing check to the top ([6404d42](https://github.com/folke/lazy.nvim/commit/6404d421555de681638907bdd4d0ab4f19774ce4))
* only run updated checker for installed plugins. Fixes [#16](https://github.com/folke/lazy.nvim/issues/16) ([ae644a6](https://github.com/folke/lazy.nvim/commit/ae644a604d4f4a4307775ccc163596a90668da34))
* show error when merging, but continue ([f78d8bf](https://github.com/folke/lazy.nvim/commit/f78d8bf376a86349de99696c4004c36b97e859e4))
* use jobstart instead of system to open urls ([1754056](https://github.com/folke/lazy.nvim/commit/175405647587d4d49e3b9c0992c6a8ae31cda706))

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
