local ffi = require("ffi")
local uv = vim.loop

local M = {}

---@alias CacheHash {mtime: {sec:number, nsec:number}, size:number}
---@alias CacheEntry {hash:CacheHash, modpath:string, chunk:string}

M.VERSION = 1

M.config = {
  enabled = false,
  path = vim.fn.stdpath("cache") .. "/lazy/luac",
}
M._loadfile = loadfile

M.stats = {
  find = { total = 0, time = 0, index = 0, stat = 0, not_found = 0 },
}
---@type string
M._rtp_key = nil
---@type string[]
M._rtp = nil
---@type table<string, table<string,true>>
M._topmods = {}

function M.get_rtp()
  if vim.in_fast_event() then
    return M._rtp or {}
  end
  local key = vim.go.rtp
  if vim.go.rtp ~= M._rtp_key then
    M._rtp = {}
    for _, path in ipairs(vim.api.nvim_get_runtime_file("", true)) do
      path = M.normalize(path)
      -- skip after directories
      if path:sub(-6, -1) ~= "/after" then
        M._rtp[#M._rtp + 1] = path
      end
    end
    M._rtp_key = key
  end
  return M._rtp
end

-- slightly faster/different version than vim.fs.normalize
-- we also need to have it here, since the cache will load vim.fs
function M.normalize(path)
  if path:sub(1, 1) == "~" then
    local home = vim.loop.os_homedir()
    if home:sub(-1) == "\\" or home:sub(-1) == "/" then
      home = home:sub(1, -2)
    end
    path = home .. path:sub(2)
  end
  path = path:gsub("\\", "/"):gsub("/+", "/")
  return path:sub(-1) == "/" and path:sub(1, -2) or path
end

function M.reset(path)
  M._topmods[M.normalize(path)] = nil
end

-- index the top-level lua modules for this path
---@return string[]
function M.get_topmods(path)
  if not M._topmods[path] then
    M.stats.find.index = M.stats.find.index + 1
    M._topmods[path] = {}
    local handle = vim.loop.fs_scandir(path .. "/lua")
    while handle do
      local name, t = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end
      ---@cast name string
      ---@cast t "file"|"directory"|"link"
      -- HACK: type is not always returned due to a bug in luv
      t = t or vim.loop.fs_stat(path .. "/" .. name).type
      ---@type string
      local topname
      if name:sub(-4) == ".lua" then
        topname = name:sub(1, -5)
      elseif t == "link" or t == "directory" then
        topname = name
      end
      if topname then
        M._topmods[path][topname] = true
      end
    end
  end
  return M._topmods[path]
end

---@param modname string
---@param opts? {rtp:string[], patterns:string[]}
---@return string?, CacheHash?
function M.find(modname, opts)
  opts = opts or {}
  local start = uv.hrtime()
  M.stats.find.total = M.stats.find.total + 1
  modname = modname:gsub("/", ".")
  local basename = modname:gsub("%.", "/")
  local idx = modname:find(".", 1, true)
  local topmod = idx and modname:sub(1, idx - 1) or modname

  -- OPTIM: search for a directory first when topmod == modname
  local patterns = opts.patterns or (topmod == modname and { "/init.lua", ".lua" } or { ".lua", "/init.lua" })
  local rtp = opts.rtp or M.get_rtp()

  for _, path in ipairs(rtp) do
    if M.get_topmods(path)[topmod] then
      for _, pattern in ipairs(patterns) do
        local modpath = path .. "/lua/" .. basename .. pattern
        M.stats.find.stat = M.stats.find.stat + 1
        local hash = uv.fs_stat(modpath)
        if hash then
          M.stats.find.time = M.stats.find.time + uv.hrtime() - start
          return modpath, hash
        end
      end
    end
  end

  -- module not found
  M.stats.find.not_found = M.stats.find.not_found + 1
  M.stats.find.time = M.stats.find.time + uv.hrtime() - start
end

function M.setup()
  M.config.enabled = true
  vim.fn.mkdir(vim.fn.fnamemodify(M.config.path, ":p"), "p")
  _G.loadfile = M.loadfile
  table.insert(package.loaders, 2, M.loader)
end

---@param name string can be a module name, or a file name
function M.cache_file(name)
  return M.config.path .. "/" .. name:gsub("[/\\]", "%%") .. ".luac"
end

---@param h1 CacheHash
---@param h2 CacheHash
function M.eq(h1, h2)
  return h1 and h2 and h1.size == h2.size and h1.mtime.sec == h2.mtime.sec and h1.mtime.nsec == h2.mtime.nsec
end

---@param entry CacheEntry
function M.write(name, entry)
  local cname = M.cache_file(name)
  local f = assert(uv.fs_open(cname, "w", 438))
  local header = {
    M.VERSION,
    entry.hash.size,
    entry.hash.mtime.sec,
    entry.hash.mtime.nsec,
    #entry.modpath,
  }
  uv.fs_write(f, ffi.string(ffi.new("const uint32_t[5]", header), 20))
  uv.fs_write(f, entry.modpath)
  uv.fs_write(f, entry.chunk)
  uv.fs_close(f)
end

---@return CacheEntry?
function M.read(name)
  local cname = M.cache_file(name)
  local f = uv.fs_open(cname, "r", 438)
  if f then
    local hash = uv.fs_fstat(f) --[[@as CacheHash]]
    local data = uv.fs_read(f, hash.size, 0) --[[@as string]]
    uv.fs_close(f)

    ---@type integer[]|{[0]:integer}
    local header = ffi.cast("uint32_t*", ffi.new("const char[20]", data:sub(1, 20)))
    if header[0] ~= M.VERSION then
      return
    end
    local modpath = data:sub(21, 20 + header[4])
    return {
      hash = { size = header[1], mtime = { sec = header[2], nsec = header[3] } },
      chunk = data:sub(20 + header[4] + 1),
      modpath = modpath,
    }
  end
end

---@param modname string
function M.loader(modname)
  modname = modname:gsub("/", ".")

  local modpath, hash = M.find(modname)
  ---@type function?, string?
  local chunk, err
  if modpath then
    chunk, err = M._load(modname, modpath, { hash = hash })
  end
  return chunk or err or ("module " .. modname .. " not found")
end

---@param modpath string
---@return any, string?
function M.loadfile(modpath)
  modpath = M.normalize(modpath)
  return M._load(modpath, modpath)
end

function M.check_loaded(modname)
  ---@diagnostic disable-next-line: no-unknown
  local mod = package.loaded[modname]
  if type(mod) == "table" then
    return function()
      return mod
    end
  end
end

---@param modkey string
---@param modpath string
---@param opts? {hash?: CacheHash, entry?:CacheEntry}
---@return function?, string? error_message
function M._load(modkey, modpath, opts)
  opts = opts or {}
  if not M.config.enabled then
    return M._loadfile(modpath)
  end
  ---@type function?, string?
  local chunk, err
  chunk = M.check_loaded(modkey)
  if chunk then
    return chunk
  end
  local hash = opts.hash or uv.fs_stat(modpath)
  if not hash then
    -- trigger correct error
    return M._loadfile(modpath)
  end

  local entry = opts.entry or M.read(modkey)
  if entry and M.eq(entry.hash, hash) then
    -- found in cache and up to date
    chunk, err = loadstring(entry.chunk --[[@as string]], "@" .. entry.modpath)
    if not (err and err:find("cannot load incompatible bytecode", 1, true)) then
      return chunk, err
    end
  end
  entry = { hash = hash, modpath = modpath }

  chunk, err = M._loadfile(entry.modpath)
  if chunk then
    entry.chunk = string.dump(chunk)
    M.write(modkey, entry)
  end
  return chunk, err
end

return M
