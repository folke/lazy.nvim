local ffi = require("ffi")
---@diagnostic disable-next-line: no-unknown
local uv = vim.loop

local M = {}
M.dirty = false
M.VERSION = "1" .. jit.version

---@class LazyCacheConfig
M.config = {
  enabled = true,
  path = vim.fn.stdpath("cache") .. "/lazy/cache",
  -- Once one of the following events triggers, caching will be disabled.
  -- To cache all modules, set this to `{}`, but that is not recommended.
  -- The default is to disable on:
  --  * VimEnter: not useful to cache anything else beyond startup
  --  * BufReadPre: this will be triggered early when opening a file from the command line directly
  disable_events = { "UIEnter", "BufReadPre" },
  ttl = 3600 * 24 * 5, -- keep unused modules for up to 5 days
}
M.debug = false

---@type CacheHash
local cache_hash

---@alias CacheHash {mtime: {sec:number, nsec:number}, size:number}
---@alias CacheEntry {hash:CacheHash, modpath:string, chunk:string, used:number}
---@type table<string,CacheEntry?>
M.cache = {}
M.enabled = true
---@type string[]
M.rtp = nil
M.rtp_total = 0
M.stats = {
  find = { total = 0, time = 0, rtp = 0, unloaded = 0, index = 0, stat = 0, not_found = 0 },
  autoload = { total = 0, time = 0 },
}
M.me = debug.getinfo(1, "S").source:sub(2)
M.me = vim.fn.fnamemodify(M.me, ":p:h:h:h:h"):gsub("\\", "/")
---@type table<string, string[]>
M.topmods = { lazy = { M.me } }
---@type table<string, string[]>
M.indexed = { [M.me] = { "lazy" } }
M.indexed_unloaded = false
M.indexed_rtp = 0
-- selene:allow(global_usage)
M._loadfile = _G.loadfile

-- checks whether the cached modpath is still valid
function M.check_path(modname, modpath)
  -- HACK: never return packer paths
  if modpath:find("/site/pack/packer/", 1, true) then
    return false
  end

  -- check rtp excluding plugins. This is a very small list, so should be fast
  for _, path in ipairs(M.get_rtp()) do
    if modpath:find(path, 1, true) == 1 then
      return true
    end
  end

  -- the correct lazy path should be part of rtp.
  -- so if we get here, this is folke using the local dev instance ;)
  if modname and (modname == "lazy" or modname:sub(1, 5) == "lazy.") then
    return false
  end

  return modname and M.check_autoload(modname, modpath)
end

function M.check_autoload(modname, modpath)
  local start = uv.hrtime()
  M.stats.autoload.total = M.stats.autoload.total + 1
  -- check plugins. Again fast, since we check the plugin name from the path.
  -- only needed when the plugin mod has been loaded
  ---@type LazyCorePlugin
  local Plugin = package.loaded["lazy.core.plugin"]
  if Plugin then
    local plugin = Plugin.find(modpath)
    if plugin and modpath:find(plugin.dir, 1, true) == 1 then
      -- we're not interested in loader time, so calculate delta here
      M.stats.autoload.time = M.stats.autoload.time + uv.hrtime() - start
      -- only autoload when plugins have been loaded
      if #require("lazy.core.config").plugins > 0 then
        if not plugin._.loaded then
          if plugin.module == false then
            error("Plugin " .. plugin.name .. " is not loaded and is configured with module=false")
          end
          require("lazy.core.loader").load(plugin, { require = modname })
        end
      end
      return true
    end
  end
  M.stats.autoload.time = M.stats.autoload.time + uv.hrtime() - start
  return false
end

function M.disable()
  if not M.enabled then
    return
  end
  if M.debug and vim.tbl_count(M.topmods) > 1 then
    vim.schedule(function()
      vim.notify("topmods:\n" .. vim.inspect(M.topmods), vim.log.levels.WARN, { title = "lazy.nvim" })
    end)
  end
  -- selene:allow(global_usage)
  _G.loadfile = M._loadfile
  M.enabled = false
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

---@param modname string
---@return fun()|string
function M.loader(modname)
  modname = modname:gsub("/", ".")
  local entry = M.cache[modname]

  local chunk, err
  if entry and M.check_path(modname, entry.modpath) then
    M.stats.find.total = M.stats.find.total + 1
    chunk, err = M.load(modname, entry.modpath)
  end
  if not chunk then
    -- find the modpath and load the module
    local modpath = M.find(modname)
    if modpath then
      M.check_autoload(modname, modpath)
      if M.enabled then
        chunk, err = M.load(modname, modpath)
      else
        chunk = M.check_loaded(modname)
        if not chunk then
          chunk, err = M._loadfile(modpath)
        end
      end
    end
  end
  return chunk or err or ("module " .. modname .. " not found")
end

---@param modpath string
---@return any, string?
function M.loadfile(modpath)
  modpath = modpath:gsub("\\", "/")
  return M.load(modpath, modpath)
end

---@param modkey string
---@param modpath string
---@return function?, string? error_message
function M.load(modkey, modpath)
  local chunk, err
  chunk = M.check_loaded(modkey)
  if chunk then
    return chunk
  end
  modpath = modpath:gsub("\\", "/")
  local hash = M.hash(modpath)
  if not hash then
    -- trigger correct error
    return M._loadfile(modpath)
  end

  local entry = M.cache[modkey]
  if entry then
    entry.modpath = modpath
    entry.used = os.time()
    if M.eq(entry.hash, hash) then
      -- found in cache and up to date
      chunk, err = loadstring(entry.chunk --[[@as string]], "@" .. entry.modpath)
      if not (err and err:find("cannot load incompatible bytecode", 1, true)) then
        return chunk, err
      end
    end
  else
    entry = { hash = hash, modpath = modpath, used = os.time() }
    M.cache[modkey] = entry
  end
  entry.hash = hash

  if M.debug and M.enabled then
    vim.schedule(function()
      vim.notify("[cache:load] " .. modpath)
    end)
  end

  chunk, err = M._loadfile(entry.modpath)
  M.dirty = true
  if chunk then
    entry.chunk = string.dump(chunk)
  else
    M.cache[modkey] = nil
  end
  return chunk, err
end

-- index the top-level lua modules for this path
function M._index(path)
  if not M.indexed[path] and path:sub(-6, -1) ~= "/after" then
    M.stats.find.index = M.stats.find.index + 1
    ---@type LazyUtilCore
    local Util = package.loaded["lazy.core.util"]
    if not Util then
      return false
    end
    M.indexed[path] = {}
    Util.ls(path .. "/lua", function(_, name, t)
      local topname
      if name:sub(-4) == ".lua" then
        topname = name:sub(1, -5)
      elseif t == "link" or t == "directory" then
        topname = name
      end
      if topname then
        M.topmods[topname] = M.topmods[topname] or {}
        if not vim.tbl_contains(M.topmods[topname], path) then
          table.insert(M.topmods[topname], path)
        end
        table.insert(M.indexed[path], topname)
      end
    end)
    return true
  end
  return false
end

function M.get_topmods(path)
  M._index(path)
  return M.indexed[path] or {}
end

---@param modname string
---@return string?, string?
function M.find_dir(modname)
  if M.cache[modname] then
    -- check if modname is in cache
    local modpath = M.cache[modname].modpath
    if M.check_path(modname, modpath) then
      local root = modpath:gsub("/init%.lua$", ""):gsub("%.lua$", "")
      return root, modpath
    end
  else
    -- in case modname is just a directory and not a real mod,
    -- check for any children in the cache
    for child, entry in pairs(M.cache) do
      if child:find(modname, 1, true) == 1 then
        if M.check_path(child, entry.modpath) then
          local basename = modname:gsub("%.", "/")
          local childbase = child:gsub("%.", "/")
          local ret = entry.modpath:gsub("/init%.lua$", ""):gsub("%.lua$", "")
          local idx = assert(ret:find(childbase, 1, true))
          return ret:sub(1, idx - 1) .. basename
        end
      end
    end
  end

  -- not found in cache, so find the root with the special pattern
  local modpath = M.find(modname, { patterns = { "" } })
  if modpath then
    local root = modpath:gsub("/init%.lua$", ""):gsub("%.lua$", "")
    return root, root ~= modpath and modpath or nil
  end
end

---@param modname string
---@param opts? {patterns?:string[]}
---@return string?
function M.find(modname, opts)
  opts = opts or {}

  M.stats.find.total = M.stats.find.total + 1
  local start = uv.hrtime()
  local basename = modname:gsub("%.", "/")
  local idx = modname:find(".", 1, true)
  local topmod = idx and modname:sub(1, idx - 1) or modname

  -- search for a directory first when topmod == modname
  local patterns = topmod == modname and { "/init.lua", ".lua" } or { ".lua", "/init.lua" }

  if opts.patterns then
    vim.list_extend(patterns, opts.patterns)
  end

  -- check top-level mods to find the module
  local function _find()
    for _, toppath in ipairs(M.topmods[topmod] or {}) do
      for _, pattern in ipairs(patterns) do
        local path = toppath .. "/lua/" .. basename .. pattern
        M.stats.find.stat = M.stats.find.stat + 1
        if uv.fs_stat(path) then
          return path
        end
      end
    end
  end

  local modpath = _find()
  if not modpath then
    -- update rtp
    local rtp = M.list_rtp()
    if #rtp ~= M.indexed_rtp then
      M.indexed_rtp = #rtp
      local updated = false
      for _, path in ipairs(rtp) do
        updated = M._index(path) or updated
      end
      if updated then
        modpath = _find()
      end
    end

    -- update unloaded
    if not modpath and not M.indexed_unloaded then
      M.indexed_unloaded = true
      local updated = false
      ---@type LazyCoreConfig
      local Config = package.loaded["lazy.core.config"]
      if Config then
        for _, plugin in pairs(Config.spec.plugins) do
          if not (M.indexed[plugin.dir] or plugin._.loaded or plugin.module == false) then
            updated = M._index(plugin.dir) or updated
          end
        end
      end
      if updated then
        modpath = _find()
      end
    end

    -- module not found
    if not modpath then
      M.stats.find.not_found = M.stats.find.not_found + 1
    end
  end

  M.stats.find.time = M.stats.find.time + uv.hrtime() - start
  return modpath
end

-- returns the cached RTP excluding plugin dirs
function M.get_rtp()
  local rtp = M.list_rtp()
  if not M.rtp or #rtp ~= M.rtp_total then
    M.rtp_total = #rtp
    M.rtp = {}
    ---@type table<string,true>
    local skip = {}
    -- only skip plugins once Config has been setup
    ---@type LazyCoreConfig
    local Config = package.loaded["lazy.core.config"]
    if Config then
      for _, plugin in pairs(Config.plugins) do
        if plugin.name ~= "lazy.nvim" then
          skip[plugin.dir] = true
        end
      end
    end
    for _, path in ipairs(rtp) do
      ---@type string
      path = path:gsub("\\", "/")
      if not skip[path] and not path:find("after/?$") then
        M.rtp[#M.rtp + 1] = path
      end
    end
  end
  return M.rtp
end

function M.list_rtp()
  return vim.api.nvim_get_runtime_file("", true)
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
  M.enabled = M.config.enabled

  if M.enabled then
    table.insert(package.loaders, 2, M.loader)
    M.load_cache()
    -- selene:allow(global_usage)
    _G.loadfile = M.loadfile
    if #M.config.disable_events > 0 then
      vim.api.nvim_create_autocmd(M.config.disable_events, { once = true, callback = M.disable })
    end
  else
    -- we need to always add the loader since this will autoload unloaded modules
    table.insert(package.loaders, M.loader)
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
  vim.fn.mkdir(vim.fn.fnamemodify(M.config.path, ":p:h"), "p")
  local f = assert(uv.fs_open(M.config.path, "w", 438))
  uv.fs_write(f, M.VERSION)
  uv.fs_write(f, "\0")
  for modname, entry in pairs(M.cache) do
    if entry.used > os.time() - M.config.ttl then
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
