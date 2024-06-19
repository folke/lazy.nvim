# ⚡ Profiling

Great care has been taken to make the startup code (`lazy.core`) as efficient as possible.
During startup, all Lua files used before `VimEnter` or `BufReadPre` are byte-compiled and cached,
similar to what [impatient.nvim](https://github.com/lewis6991/impatient.nvim) does.

My config for example loads in about `11ms` with `93` plugins. I do a lot of lazy-loading though :)

**lazy.nvim** comes with an advanced profiler `:Lazy profile` to help you improve performance.
The profiling view shows you why and how long it took to load your plugins.

![image](https://user-images.githubusercontent.com/292349/208301766-5c400561-83c3-4811-9667-1ec4bb3c43b8.png)
