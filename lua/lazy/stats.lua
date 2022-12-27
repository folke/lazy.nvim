local M = {}

---@class LazyStats
M._stats = {
  -- startuptime in milliseconds till UIEnter
  startuptime = 0,
  -- when true, startuptime is the accurate cputime for the Neovim process. (Linux & Macos)
  -- this is more accurate than `nvim --startuptime`, and as such will be slightly higher
  -- when false, startuptime is calculated based on a delta with a timestamp when lazy started.
  startuptime_cputime = false,
  count = 0, -- total number of plugins
  loaded = 0, -- number of loaded plugins
}

function M.on_ui_enter()
  if not M.C then
    pcall(function() end)
  end

  local ok = pcall(function()
    local ffi = require("ffi")
    ffi.cdef([[
        typedef long time_t;
        typedef int clockid_t;

        typedef struct timespec {
          time_t   tv_sec;        /* seconds */
          long     tv_nsec;       /* nanoseconds */
        } nanotime;
        int clock_gettime(clockid_t clk_id, struct timespec *tp);
      ]])
    local pnano = assert(ffi.new("nanotime[?]", 1))
    local CLOCK_PROCESS_CPUTIME_ID = jit.os == "OSX" and 12 or 2
    ffi.C.clock_gettime(CLOCK_PROCESS_CPUTIME_ID, pnano)
    M._stats.startuptime = tonumber(pnano[0].tv_sec) / 1e6 + tonumber(pnano[0].tv_nsec) / 1e6
    M._stats.startuptime_cputime = true
  end)
  if not ok then
    M._stats.startuptime = (vim.loop.hrtime() - require("lazy")._start) / 1e6
  end
  vim.cmd([[do User LazyVimStarted]])
end

function M.stats()
  M._stats.count = 0
  M._stats.loaded = 0
  for _, plugin in pairs(require("lazy.core.config").plugins) do
    M._stats.count = M._stats.count + 1
    if plugin._.loaded then
      M._stats.loaded = M._stats.loaded + 1
    end
  end
  return M._stats
end

return M
