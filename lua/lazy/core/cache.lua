local ffi = require("ffi")
local uv = vim.loop

local M = {}

---@alias CacheHash {mtime: {sec:number, nsec:number}, size:number}
---@alias CacheEntry {hash:CacheHash, modpath:string, chunk:string}

---@class CacheFindOpts
---@field rtp? boolean Search for modname in the runtime path (defaults to `true`)
---@field patterns? string[] Paterns to use (defaults to `{"/init.lua", ".lua"}`)
---@field paths? string[] Extra paths to search for modname

M.VERSION = 1
M.path = vim.fn.stdpath("cache") .. "/lazy/luac"
M.enabled = false
M.stats = { total = 0, time = 0, index = 0, stat = 0, not_found = 0 }

---@class ModuleCache
---@field _rtp string[]
---@field _rtp_key string
local Cache = {
  ---@type table<string, table<string,true>>
  _topmods = {},
  _loadfile = loadfile,
}

-- slightly faster/different version than vim.fs.normalize
-- we also need to have it here, since the cache will load vim.fs
---@private
function Cache.normalize(path)
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

---@private
function Cache.get_rtp()
  if vim.in_fast_event() then
    return Cache._rtp or {}
  end
  local key = vim.go.rtp
  if key ~= Cache._rtp_key then
    Cache._rtp = {}
    for _, path in ipairs(vim.api.nvim_get_runtime_file("", true)) do
      path = Cache.normalize(path)
      -- skip after directories
      if path:sub(-6, -1) ~= "/after" then
        Cache._rtp[#Cache._rtp + 1] = path
      end
    end
    Cache._rtp_key = key
  end
  return Cache._rtp
end

---@param name string can be a module name, or a file name
---@private
function Cache.cache_file(name)
  return M.path .. "/" .. name:gsub("[/\\]", "%%") .. ".luac"
end

---@param entry CacheEntry
---@private
function Cache.write(name, entry)
  local cname = Cache.cache_file(name)
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
---@private
function Cache.read(name)
  local cname = Cache.cache_file(name)
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
---@private
function Cache.loader(modname)
  modname = modname:gsub("/", ".")
  local modpath, hash = Cache.find(modname)
  if modpath then
    return Cache.load(modpath, { hash = hash })
  end
  return "module " .. modname .. " not found"
end

---@param filename? string
---@param mode? "b"|"t"|"bt"
---@param env? table
---@return function?, string?  error_message
---@private
function Cache.loadfile(filename, mode, env)
  filename = Cache.normalize(filename)
  return Cache.load(filename, { mode = mode, env = env })
end

---@param h1 CacheHash
---@param h2 CacheHash
---@private
function Cache.eq(h1, h2)
  return h1 and h2 and h1.size == h2.size and h1.mtime.sec == h2.mtime.sec and h1.mtime.nsec == h2.mtime.nsec
end

---@param modpath string
---@param opts? {hash?: CacheHash, mode?: "b"|"t"|"bt", env?:table}
---@return function?, string? error_message
---@private
function Cache.load(modpath, opts)
  opts = opts or {}
  local hash = opts.hash or uv.fs_stat(modpath)
  if not hash then
    -- trigger correct error
    return Cache._loadfile(modpath)
  end

  ---@type function?, string?
  local chunk, err
  local entry = Cache.read(modpath)
  if entry and Cache.eq(entry.hash, hash) then
    -- found in cache and up to date
    chunk, err = loadstring(entry.chunk --[[@as string]], "@" .. entry.modpath)
    if not (err and err:find("cannot load incompatible bytecode", 1, true)) then
      return chunk, err
    end
  end
  entry = { hash = hash, modpath = modpath }

  chunk, err = Cache._loadfile(entry.modpath)
  if chunk then
    entry.chunk = string.dump(chunk)
    Cache.write(modpath, entry)
  end
  return chunk, err
end

---@param modname string
---@param opts? CacheFindOpts
---@return string? modpath, CacheHash? hash
function Cache.find(modname, opts)
  opts = opts or {}
  local start = uv.hrtime()
  M.stats.total = M.stats.total + 1
  modname = modname:gsub("/", ".")
  local basename = modname:gsub("%.", "/")
  local idx = modname:find(".", 1, true)
  local topmod = idx and modname:sub(1, idx - 1) or modname

  -- OPTIM: search for a directory first when topmod == modname
  local patterns = opts.patterns or (topmod == modname and { "/init.lua", ".lua" } or { ".lua", "/init.lua" })
  local rtp = opts.rtp ~= false and Cache.get_rtp() or {}
  if opts.paths then
    rtp = vim.deepcopy(rtp)
    for _, dir in ipairs(opts.paths) do
      rtp[#rtp + 1] = Cache.normalize(dir)
    end
  end
  for p, pattern in ipairs(patterns) do
    patterns[p] = "/lua/" .. basename .. pattern
  end

  for _, path in ipairs(rtp) do
    if M.lsmod(path)[topmod] then
      for _, pattern in ipairs(patterns) do
        local modpath = path .. pattern
        M.stats.stat = M.stats.stat + 1
        local hash = uv.fs_stat(modpath)
        if hash then
          M.stats.time = M.stats.time + uv.hrtime() - start
          return modpath, hash
        end
      end
    end
  end

  -- module not found
  M.stats.not_found = M.stats.not_found + 1
  M.stats.time = M.stats.time + uv.hrtime() - start
end

--- Resets the topmods cache for the path
---@param path string
function M.reset(path)
  Cache._topmods[Cache.normalize(path)] = nil
end

function M.enable()
  if M.enabled then
    return
  end
  M.enabled = true
  vim.fn.mkdir(vim.fn.fnamemodify(M.path, ":p"), "p")
  -- selene: allow(global_usage)
  _G.loadfile = Cache.loadfile
  table.insert(package.loaders, 2, Cache.loader)
end

function M.disable()
  if not M.enabled then
    return
  end
  M.enabled = false
  -- selene: allow(global_usage)
  _G.loadfile = Cache._loadfile
  ---@diagnostic disable-next-line: no-unknown
  for l, loader in ipairs(package.loaders) do
    if loader == Cache.loader then
      table.remove(package.loaders, l)
    end
  end
end

-- Return the top-level `/lua/*` modules for this path
---@return string[]
function M.lsmod(path)
  if not Cache._topmods[path] then
    M.stats.index = M.stats.index + 1
    Cache._topmods[path] = {}
    local handle = vim.loop.fs_scandir(path .. "/lua")
    while handle do
      local name, t = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end
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
        Cache._topmods[path][topname] = true
      end
    end
  end
  return Cache._topmods[path]
end

---@param modname string
---@param opts? CacheFindOpts
---@return string? modpath
function M.find(modname, opts)
  local modpath = Cache.find(modname, opts)
  return modpath
end

function M.inspect()
  local function ms(nsec)
    return math.floor(nsec / 1e6 * 1000 + 0.5) / 1000 .. "ms"
  end
  local props = {
    { "total", M.stats.total, "Number" },
    { "time", ms(M.stats.time), "Bold" },
    { "avg time", ms(M.stats.time / M.stats.total), "Bold" },
    { "index", M.stats.index, "Number" },
    { "fs_stat", M.stats.stat, "Number" },
    { "not found", M.stats.not_found, "Number" },
  }
  local chunks = {} ---@type string[][]
  for _, prop in ipairs(props) do
    chunks[#chunks + 1] = { "* " .. prop[1] .. ": " }
    chunks[#chunks + 1] = { tostring(prop[2]) .. "\n", prop[3] }
  end
  vim.api.nvim_echo(chunks, true, {})
end

M._Cache = Cache

return M
