local ffi = require("ffi")
---@diagnostic disable-next-line: no-unknown
local uv = vim.loop

local M = {}
M.dirty = false

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
M.loader_idx = 2 -- 2 so preload still works
M.enabled = true
M.ttl = 3600 * 24 * 5 -- keep unused modules for up to 5 days

-- Check if we need to load this plugin
---@param modname string
---@param modpath string
function M.check_load(modname, modpath)
  if modname:sub(1, 4) == "lazy" then
    return
  end
  require("lazy.core.loader").check_load(modname, modpath)
end

function M.disable()
  if not M.enabled then
    return
  end
  local idx = M.idx()
  if idx then
    table.remove(package.loaders, idx)
  end
  M.enabled = false
end

---@param modname string
---@return any
function M.loader(modname)
  local entry = M.cache[modname]

  local chunk, err
  if entry then
    M.check_load(modname, entry.modpath)
    entry.used = os.time()
    local hash = M.hash(entry.modpath)
    if not hash then
      return
    end
    if M.eq(entry.hash, hash) then
      -- found in cache and up to date
      chunk, err = load(entry.chunk --[[@as string]], "@" .. entry.modpath)
      return chunk or error(err)
    end
    -- reload from file
    entry.hash = hash
    chunk, err = loadfile(entry.modpath)
  else
    -- load the module and find its modpath
    local modpath
    chunk, modpath = M.find(modname)
    if modpath then
      entry = { hash = M.hash(modpath), modpath = modpath, used = os.time() }
      M.cache[modname] = entry
    end
  end
  if M.debug then
    vim.schedule(function()
      vim.notify("[cache:load] " .. modname)
    end)
  end
  if entry and chunk then
    M.dirty = true
    entry.chunk = string.dump(chunk)
  end
  return chunk or error(err)
end

function M.require(modname)
  return M.loader(modname)()
end

function M.idx()
  -- update our loader position if needed
  if package.loaders[M.loader_idx] ~= M.loader then
    M.loader_idx = nil
    ---@diagnostic disable-next-line: no-unknown
    for i, loader in ipairs(package.loaders) do
      if loader == M.loader then
        M.loader_idx = i
        break
      end
    end
  end
  return M.loader_idx
end

---@param modname string
function M.find(modname)
  if M.idx() then
    -- find the module and its modpath
    for i = M.loader_idx + 1, #package.loaders do
      ---@diagnostic disable-next-line: no-unknown
      local chunk = package.loaders[i](modname)
      if type(chunk) == "function" then
        local info = debug.getinfo(chunk, "S")
        return chunk, (info.what ~= "C" and info.source:sub(2))
      end
    end
  end
end

---@param opts? LazyConfig
function M.setup(opts)
  -- no fancy deep extend here. just set the options
  if opts and opts.performance and opts.performance.cache then
    for k, v in pairs(opts.performance.cache) do
      M.config[k] = v
    end
  end
  M.debug = opts and opts.debug

  M.load_cache()
  table.insert(package.loaders, M.loader_idx, M.loader)

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
  uv.fs_write(f, vim.env.VIMRUNTIME)
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

    if vim.env.VIMRUNTIME ~= data:sub(1, zero - 1) then
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
