local Cache = require("lazy.core.cache")

local M = {}

---@type table<string, {file: string, hash?:string}>
M.modules = {}

function M.add(modname, file)
  if not M.modules[modname] then
    M.modules[modname] = { file = file }
  end
end

---@param modname string
function M.load(modname)
  if type(package.loaded[modname]) == "table" then
    return package.loaded[modname]
  end

  local info = M.modules[modname]
  if info then
    local err
    ---@type string|fun()|nil
    local chunk = Cache.get(modname)

    if not chunk then
      vim.schedule(function()
        vim.notify("loading " .. modname)
      end)
      chunk, err = loadfile(info.file)
      if chunk then
        Cache.set(modname, string.dump(chunk))
        info.hash = info.hash or Cache.hash(info.file)
      end
    end

    if type(chunk) == "string" then
      chunk, err = loadstring(chunk --[[@as string]], "@" .. info.file)
    end

    if not chunk then
      error(err)
    end

    ---@type table
    local mod = chunk()
    package.loaded[modname] = mod
    return mod
  end
end

local function _add_module(dir, modname)
  local d = vim.loop.fs_opendir(dir, nil, 100)
  if d then
    ---@type {name: string, type: "file"|"directory"|"link"}[]
    local entries = vim.loop.fs_readdir(d)
    while entries do
      for _, entry in ipairs(entries) do
        local path = dir .. "/" .. entry.name
        if entry.type == "directory" then
          _add_module(path, modname .. "." .. entry.name)
        else
          local childname = entry.name:match("^(.*)%.lua$")
          if childname then
            local child = entry.name == "init.lua" and modname or (modname .. "." .. childname)
            if child then
              M.add(child, path)
            end
          end
        end
      end
      entries = vim.loop.fs_readdir(d)
    end
    vim.loop.fs_closedir(d)
  end
end

function M.add_module(path)
  ---@type string
  local modname = path:match("/lua/(.*)/?")
  assert(modname)
  modname = modname:gsub("/", ".")
  if vim.loop.fs_stat(path .. ".lua") then
    M.add(modname, path .. ".lua")
  end
  _add_module(path, modname)
end

function M.setup()
  -- load cache
  local value = Cache.get("cache.modules")
  if value then
    M.modules = vim.json.decode(value)
    for k, v in pairs(M.modules) do
      if Cache.hash(v.file) ~= v.hash then
        Cache.del(k)
        M.changed = true
        M.modules[k] = nil
      end
    end
  end

  -- preload core modules
  local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
  for _, name in ipairs({ "util", "config", "plugin", "loader", "core.state" }) do
    local modname = "lazy." .. name
    M.add(modname, root .. "/" .. name:gsub("%.", "/") .. ".lua")
  end

  table.insert(package.loaders, 2, function(modname)
    if M.modules[modname] then
      return function()
        return M.load(modname)
      end
    end
  end)
  return M
end

function M.save()
  local value = {}
  for k, v in pairs(M.modules) do
    if v.hash then
      value[k] = v
    end
  end
  Cache.set("cache.modules", vim.json.encode(value))
end

return M
