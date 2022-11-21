local M = {}

---@class CacheOptions
M.options = {
  module = "config.plugins",
  cache = vim.fn.stdpath("state") .. "/lazy/plugins.state",
  trim = false,
}

M.dirty = false
M.cache_hash = ""

---@alias ModEntry {file: string, hash?:string, chunk?: string|fun(), used?: boolean}
---@type table<string,ModEntry>
M.modules = {}

---@type LazyState?
M.state = nil

---@alias DirEntry {name: string, type: "file"|"directory"|"link"}

function M.walk(dir, modname, fn)
  local d = vim.loop.fs_opendir(dir, nil, 100)
  if d then
    ---@type DirEntry[]
    local entries = vim.loop.fs_readdir(d)
    while entries do
      for _, entry in ipairs(entries) do
        local path = dir .. "/" .. entry.name
        if entry.type == "directory" then
          M.walk(path, modname .. "." .. entry.name, fn)
        else
          local child = entry.name == "init.lua" and modname or (modname .. "." .. entry.name:match("^(.*)%.lua$"))
          if child then
            fn(child, path)
          end
        end
      end
      entries = vim.loop.fs_readdir(d)
    end
    vim.loop.fs_closedir(d)
  end
end

function M.hash(modpath)
  local stat = vim.loop.fs_stat(modpath)
  if stat then
    return stat.mtime.sec .. stat.mtime.nsec .. stat.size
  end
end

---@param opts? CacheOptions
function M.boot(opts)
  if opts then
    for k, _ in pairs(M.options) do
      M.options[k] = opts[k] or M.options[k]
    end
  end
  M.load_state()

  -- preload core modules
  local root = debug.getinfo(1, "S").source:sub(2)
  root = vim.fn.fnamemodify(root, ":p:h")
  for _, modname in ipairs({ "util", "config", "plugin", "loader" }) do
    local file = root .. "/" .. modname .. ".lua"
    modname = "lazy." .. modname
    if not M.modules[modname] then
      M.modules[modname] = { file = file }
    end
    package.preload[modname] = function()
      return M.load(modname)
    end
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyDone",
    once = true,
    callback = function()
      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          if M.dirty then
            local hash = M.hash(M.options.cache)
            -- abort when the file was changed in the meantime
            if M.hash == nil or M.cache_hash == hash then
              M.compile()
            end
          end
        end,
      })
    end,
  })

  if M.state and M.load_plugins() then
    return true
  else
    M.dirty = true
    -- FIXME: what if module is a file
    local root = vim.fn.stdpath("config") .. "/lua/" .. M.options.module:gsub("%.", "/")
    if vim.loop.fs_stat(root .. ".lua") then
      if not M.modules[M.options.module] then
        M.modules[M.options.module] = { file = root .. ".lua" }
      end
    end
    M.walk(root, M.options.module, function(modname, modpath)
      if not M.modules[modname] then
        M.modules[modname] = { file = modpath }
      end
    end)
  end
end

---@param modname string
function M.load(modname)
  local info = M.modules[modname]

  if type(package.loaded[modname]) == "table" then
    if info then
      info.used = true
    end
    return package.loaded[modname]
  end

  if info then
    local hash = M.hash(info.file)
    if hash ~= info.hash then
      info.chunk = nil
    end
    local err
    if not info.chunk then
      vim.schedule(function()
        vim.notify("loading " .. modname)
      end)
      info.chunk, err = loadfile(info.file)
      info.hash = hash
      M.dirty = true
    end
    if type(info.chunk) == "string" then
      info.chunk, err = loadstring(info.chunk --[[@as string]], "@" .. info.file)
    end
    if not info.chunk then
      error(err)
    end
    info.used = true
    ---@type table
    local mod = info.chunk()
    package.loaded[modname] = mod
    return mod
  end
end

---@param state LazyState
function M.write(state)
  local chunks = state.chunks
  state.chunks = nil

  local header = loadstring("return " .. M.dump(state))
  assert(header)
  table.insert(chunks, string.dump(header, true))

  vim.fn.mkdir(vim.fn.fnamemodify(M.options.cache, ":p:h"), "p")
  local f = assert(io.open(M.options.cache, "wb"))
  for _, chunk in ipairs(chunks) do
    f:write(tostring(#chunk), "\0", chunk)
  end
  f:close()
end

---@return LazyState?
function M.read()
  M.cache_hash = M.hash(M.options.cache)
  local f = io.open(M.options.cache, "rb")
  if f then
    ---@type string
    local data = f:read("*a")
    f:close()

    local from = 1
    local to = data:find("\0", from, true)
    ---@type string[]
    local chunks = {}
    while to do
      local len = tonumber(data:sub(from, to - 1))
      from = to + 1
      local chunk = data:sub(from, from + len - 1)
      table.insert(chunks, chunk)
      from = from + len
      to = data:find("\0", from, true)
    end

    local state = loadstring(table.remove(chunks))
    assert(state)
    ---@type LazyState
    local ret = state()
    ret.chunks = chunks
    return ret
  end
end

function M.compile()
  local Config = require("lazy.config")

  ---@class LazyState
  local state = {
    ---@type LazyPlugin[]
    plugins = {},
    ---@type table<string, {file:string, hash:string, chunk:number}>
    modules = {},
    loaders = require("lazy.loader").loaders,
    -- config = Config.options,
    ---@type string[]
    chunks = {},
  }

  local skip = { installed = true, loaded = true }

  -- plugins
  for _, plugin in pairs(Config.plugins) do
    -- mark module as used
    if M.modules[plugin.modname] then
      ---@diagnostic disable-next-line: no-unknown
      M.modules[plugin.modname].used = true
    end

    ---@type LazyPlugin | {_chunks: string[] | table<string, number>}
    local save = {}
    table.insert(state.plugins, save)
    for k, v in pairs(plugin) do
      if type(v) == "function" then
        save._chunks = save._chunks or {}
        if plugin.modname then
          table.insert(save._chunks, k)
        else
          table.insert(state.chunks, string.dump(v, M.options.trim))
          save._chunks[k] = #state.chunks
        end
      elseif not skip[k] then
        save[k] = v
      end
    end
  end

  -- modules
  for modname, entry in pairs(M.modules) do
    if entry.used and entry.chunk then
      table.insert(
        state.chunks,
        type(entry.chunk) == "string" and entry.chunk or string.dump(entry.chunk --[[@as fun()]], M.options.trim)
      )
      state.modules[modname] = { file = entry.file, hash = entry.hash, chunk = #state.chunks }
    end
  end
  M.write(state)
end

function M._dump(value, result)
  local t = type(value)
  if t == "number" or t == "boolean" then
    table.insert(result, tostring(value))
  elseif t == "string" then
    table.insert(result, ("%q"):format(value))
  elseif t == "table" then
    table.insert(result, "{")
    local i = 1
    ---@diagnostic disable-next-line: no-unknown
    for k, v in pairs(value) do
      if k == i then
      elseif type(k) == "string" then
        table.insert(result, ("[%q]="):format(k))
      else
        table.insert(result, k .. "=")
      end
      M._dump(v, result)
      table.insert(result, ",")
      i = i + 1
    end
    table.insert(result, "}")
  else
    error("Unsupported type " .. t)
  end
end

function M.dump(value)
  local result = {}
  M._dump(value, result)
  return table.concat(result, "")
end

function M.load_state()
  M.state = M.read()

  if not M.state then
    return
  end
  local reload = false
  for modname, entry in pairs(M.state.modules) do
    entry.chunk = M.state.chunks[entry.chunk]
    ---@cast entry ModEntry
    if M.hash(entry.file) ~= entry.hash then
      -- keep loading modules, but reset state (reload plugins)
      reload = true
    end
    M.modules[modname] = entry
  end
  if reload then
    M.state = nil
  end
end

local function load_plugin(plugin, fun, ...)
  local mod = M.load(plugin.modname)
  for k, v in pairs(mod) do
    if type(v) == "function" then
      plugin[k] = v
    end
  end
  return mod[fun](...)
end

function M.load_plugins()
  local Config = require("lazy.config")

  if not vim.deepcopy(Config.options, M.state.config) then
    return false
  end

  -- plugins
  for _, plugin in ipairs(M.state.plugins) do
    plugin.loaded = false
    plugin.installed = vim.loop.fs_stat(plugin.dir) and true
    if plugin._chunks then
      if plugin.modname then
        for _, fun in ipairs(plugin._chunks) do
          plugin[fun] = function(...)
            return load_plugin(plugin, fun, ...)
          end
        end
      else
        for fun, value in pairs(plugin._chunks) do
          plugin[fun] = function(...)
            plugin[fun] = loadstring(M.state.chunks[value])
            return plugin[fun](...)
          end
        end
      end
      plugin._chunks = nil
    end
  end

  -- loaders
  local Loader = require("lazy.loader")
  Loader.loaders = M.state.loaders

  -- save plugins
  Config.plugins = {}
  for _, plugin in ipairs(M.state.plugins) do
    Config.plugins[plugin.name] = plugin
  end
  return true
end

return M
