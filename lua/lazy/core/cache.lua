local ffi = require("ffi")
---@diagnostic disable-next-line: no-unknown
local uv = vim.loop

local M = {}
M.dirty = false
M.VERSION = "1"

---@class LazyCacheConfig
M.config = {
  enabled = true,
  path = vim.fn.stdpath("state") .. "/lazy.state",
  -- Once one of the following events triggers, caching will be disabled.
  -- To cache all modules, set this to `{}`, but that is not recommended.
  -- The default is to disable on:
  --  * VimEnter: not useful to cache anything else beyond startup
  --  * BufReadPre: this will be triggered early when opening a file from the command line directly
  disable_events = { "VimEnter", "BufReadPre" },
}
M.debug = false

---@type CacheHash
local cache_hash

---@alias CacheHash {mtime: {sec:number, nsec:number}, size:number}
---@alias CacheEntry {hash:CacheHash, modpath:string, chunk:string, used:number}
---@type table<string,CacheEntry?>
M.cache = {}
M.enabled = true
M.ttl = 3600 * 24 * 5 -- keep unused modules for up to 5 days
---@type string[]
M.rtp = nil
-- selene:allow(global_usage)
M._loadfile = _G.loadfile

-- checks wether the cached modpath is still valid
function M.check_path(modname, modpath)
  -- check rtp exlcuding plugins. This is a very small list, so should be fast
  for _, path in ipairs(M.get_rtp()) do
    if modpath:find(path, 1, true) == 1 then
      return true
    end
  end

  -- the correct lazy path should be part of rtp.
  -- so if we get here, this is folke using the local dev instance ;)
  if modname:sub(1, 4) == "lazy" then
    return false
  end

  -- check plugins. Again fast, since we check the plugin name from the path.
  -- only needed when the plugin mod has been loaded
  if package.loaded["lazy.core.plugin"] then
    local plugin = require("lazy.core.plugin").find(modpath)
    if plugin and modpath:find(plugin.dir, 1, true) == 1 then
      if not plugin._.loaded then
        require("lazy.core.loader").load(plugin, { require = modname })
      end
      return true
    end
  end
  return false
end

function M.disable()
  if not M.enabled then
    return
  end
  -- selene:allow(global_usage)
  _G.loadfile = M._loadfile
  ---@diagnostic disable-next-line: no-unknown
  for i, loader in ipairs(package.loaders) do
    if loader == M.loader then
      table.remove(package.loaders, i)
      break
    end
  end
  M.enabled = false
end

---@param modname string
---@return any
function M.loader(modname)
  local entry = M.cache[modname]

  local chunk, err
  if entry and M.check_path(modname, entry.modpath) then
    chunk, err = M.load(modname, entry.modpath)
  else
    -- find the modpath and load the module
    local modpath = M.find(modname)
    if modpath then
      chunk, err = M.load(modname, modpath)
    end
  end
  return chunk or (err and error(err)) or "not found in lazy cache"
end

---@param modpath string
---@return any, string?
function M.loadfile(modpath)
  return M.load(modpath, modpath)
end

---@param modkey string
---@param modpath string
---@return function?, string? error_message
function M.load(modkey, modpath)
  local hash = M.hash(modpath)
  if not hash then
    -- trigger correct error
    return M._loadfile(modpath)
  end

  local entry = M.cache[modkey]
  if entry then
    entry.used = os.time()
    if M.eq(entry.hash, hash) then
      -- found in cache and up to date
      return loadstring(entry.chunk --[[@as string]], "@" .. entry.modpath)
    end
  else
    entry = { hash = hash, modpath = modpath, used = os.time() }
    M.cache[modkey] = entry
  end
  entry.hash = hash

  if M.debug then
    vim.schedule(function()
      vim.notify("[cache:load] " .. modpath)
    end)
  end

  local chunk, err = M._loadfile(entry.modpath)
  if chunk then
    M.dirty = true
    entry.chunk = string.dump(chunk)
  end
  return chunk, err
end

function M.require(modname)
  return M.loader(modname)()
end

---@param modname string
---@return string?
function M.find(modname)
  local basename = modname:gsub("%.", "/")
  local paths = { "lua/" .. basename .. ".lua", "lua/" .. basename .. "/init.lua" }
  return vim.api.nvim__get_runtime(paths, false, { is_lua = true })[1]
end

-- returns the cached RTP excluding plugin dirs
function M.get_rtp()
  if not M.rtp then
    M.rtp = {}
    ---@type table<string,true>
    local skip = {}
    -- only skip plugins once Config has been setup
    if package.loaded["lazy.core.config"] then
      local Config = require("lazy.core.config")
      for _, plugin in pairs(Config.plugins) do
        if plugin.name ~= "lazy.nvim" then
          skip[plugin.dir] = true
        end
      end
    end
    for _, path in ipairs(vim.api.nvim_list_runtime_paths()) do
      if not skip[path] then
        M.rtp[#M.rtp + 1] = path
      end
    end
  end
  return M.rtp
end

---@param opts? LazyConfig
function M.setup(opts)
  -- no fancy deep extend here. just set the options
  if opts and opts.performance and opts.performance.cache then
    ---@diagnostic disable-next-line: no-unknown
    for k, v in pairs(opts.performance.cache) do
      ---@diagnostic disable-next-line: no-unknown
      M.config[k] = v
    end
  end
  M.debug = opts and opts.debug

  M.load_cache()
  table.insert(package.loaders, 2, M.loader)
  -- selene:allow(global_usage)
  _G.loadfile = M.loadfile

  -- reset rtp when it changes
  vim.api.nvim_create_autocmd("OptionSet", {
    pattern = "runtimepath",
    callback = function()
      M.rtp = nil
    end,
  })

  if #M.config.disable_events > 0 then
    vim.api.nvim_create_autocmd(M.config.disable_events, { once = true, callback = M.disable })
  end
  return M
end

---@return CacheHash?
function M.hash(file)
  local ok, ret = pcall(uv.fs_stat, file)
  return ok and ret or nil
end

---@param h1 CacheHash
---@param h2 CacheHash
function M.eq(h1, h2)
  return h1 and h2 and h1.size == h2.size and h1.mtime.sec == h2.mtime.sec and h1.mtime.nsec == h2.mtime.nsec
end

function M.save_cache()
  local f = assert(uv.fs_open(M.config.path, "w", 438))
  uv.fs_write(f, M.VERSION)
  uv.fs_write(f, "\0")
  for modname, entry in pairs(M.cache) do
    if entry.used > os.time() - M.ttl then
      entry.modname = modname
      local header = {
        entry.hash.size,
        entry.hash.mtime.sec,
        entry.hash.mtime.nsec,
        #modname,
        #entry.chunk,
        #entry.modpath,
        entry.used,
      }
      uv.fs_write(f, ffi.string(ffi.new("const uint32_t[7]", header), 28))
      uv.fs_write(f, modname)
      uv.fs_write(f, entry.chunk)
      uv.fs_write(f, entry.modpath)
    end
  end
  uv.fs_close(f)
end

function M.load_cache()
  M.cache = {}
  local f = uv.fs_open(M.config.path, "r", 438)
  if f then
    cache_hash = uv.fs_fstat(f) --[[@as CacheHash]]
    local data = uv.fs_read(f, cache_hash.size, 0) --[[@as string]]
    uv.fs_close(f)

    local zero = data:find("\0", 1, true)
    if not zero then
      return
    end

    if M.VERSION ~= data:sub(1, zero - 1) then
      return
    end

    local offset = zero + 1
    while offset + 1 < #data do
      local header = ffi.cast("uint32_t*", ffi.new("const char[28]", data:sub(offset, offset + 27)))
      offset = offset + 28
      local modname = data:sub(offset, offset + header[3] - 1)
      offset = offset + header[3]
      local chunk = data:sub(offset, offset + header[4] - 1)
      offset = offset + header[4]
      local file = data:sub(offset, offset + header[5] - 1)
      offset = offset + header[5]
      M.cache[modname] = {
        hash = { size = header[0], mtime = { sec = header[1], nsec = header[2] } },
        chunk = chunk,
        modpath = file,
        used = header[6],
      }
    end
  end
end

function M.autosave()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if M.dirty then
        local hash = M.hash(M.config.path)
        -- abort when the file was changed in the meantime
        if hash == nil or M.eq(cache_hash, hash) then
          M.save_cache()
        end
      end
    end,
  })
end

return M
