local ffi = require("ffi")
---@diagnostic disable-next-line: no-unknown
local uv = vim.loop

local M = {}
M.dirty = false

local cache_path = vim.fn.stdpath("state") .. "/lazy.state"
---@type CacheHash
local cache_hash

---@alias CacheHash {mtime: {sec:number, nsec:number}, size:number}
---@alias CacheEntry {hash:CacheHash, chunk:string, used:boolean}
---@type table<string,CacheEntry?>
M.cache = {}

---@param modname string
---@param modpath string
---@return any
function M.load(modname, modpath)
  local entry = M.cache[modname]
  local hash = assert(M.hash(modpath))

  if entry and not M.eq(entry.hash, hash) then
    entry = nil
  end

  local chunk, err
  if entry then
    entry.used = true
    chunk, err = load(entry.chunk --[[@as string]], "@" .. modpath, "b")
  else
    vim.schedule(function()
      vim.notify("loadfile(" .. modname .. ")")
    end)
    chunk, err = loadfile(modpath)
    if chunk then
      M.dirty = true
      M.cache[modname] = { hash = hash, chunk = string.dump(chunk), used = true }
    end
  end

  return chunk and chunk() or error(err)
end

function M.setup()
  M.load_cache()
  -- preload core modules
  local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
  for _, name in ipairs({ "util", "config", "loader", "plugin", "handler" }) do
    local modname = "lazy.core." .. name
    ---@diagnostic disable-next-line: no-unknown
    package.preload[modname] = function()
      return M.load(modname, root .. "/core/" .. name:gsub("%.", "/") .. ".lua")
    end
  end
  return M
end

---@return CacheHash?
function M.hash(file)
  return uv.fs_stat(file)
end

---@param h1 CacheHash
---@param h2 CacheHash
function M.eq(h1, h2)
  return h1 and h2 and h1.size == h2.size and h1.mtime.sec == h2.mtime.sec and h1.mtime.nsec == h2.mtime.nsec
end

function M.save_cache()
  local f = assert(uv.fs_open(cache_path, "w", 438))
  vim.loop.fs_ftruncate(f, 0)
  for modname, entry in pairs(M.cache) do
    if entry.used then
      entry.modname = modname
      local header = { entry.hash.size, entry.hash.mtime.sec, entry.hash.mtime.nsec, #modname, #entry.chunk }
      uv.fs_write(f, ffi.string(ffi.new("const uint32_t[5]", header), 20))
      uv.fs_write(f, modname)
      uv.fs_write(f, entry.chunk)
    end
  end
  uv.fs_close(f)
end

function M.load_cache()
  M.cache = {}
  local f = uv.fs_open(cache_path, "r", 438)
  if f then
    cache_hash = uv.fs_fstat(f) --[[@as CacheHash]]
    local data = uv.fs_read(f, cache_hash.size, 0) --[[@as string]]
    uv.fs_close(f)

    local offset = 1
    while offset + 1 < #data do
      local header = ffi.cast("uint32_t*", ffi.new("const char[20]", data:sub(offset, offset + 19)))
      offset = offset + 20
      local modname = data:sub(offset, offset + header[3] - 1)
      offset = offset + header[3]
      local chunk = data:sub(offset, offset + header[4] - 1)
      offset = offset + header[4]
      M.cache[modname] = { hash = { size = header[0], mtime = { sec = header[1], nsec = header[2] } }, chunk = chunk }
    end
  end
end

function M.autosave()
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      if M.dirty then
        local hash = M.hash(cache_path)
        -- abort when the file was changed in the meantime
        if hash == nil or M.eq(cache_hash, hash) then
          M.save_cache()
        end
      end
    end,
  })
end

return M
