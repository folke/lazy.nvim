local Cache = require("lazy.core.cache")

local M = {}

---@type table<string, string>
M.hashes = {}

function M.is_dirty(modname, modpath)
  return not (Cache.get(modname) and M.hashes[modname] and M.hashes[modname] == Cache.hash(modpath))
end

---@param modname string
---@param modpath string
---@return table
function M.load(modname, modpath)
  local err
  ---@type (string|fun())?
  local chunk = Cache.get(modname)

  if chunk then
    local hash = Cache.hash(modpath)
    if hash ~= M.hashes[modname] then
      M.hashes[modname] = hash
      chunk = nil
    end
  end

  if chunk then
    chunk, err = loadstring(chunk --[[@as string]], "@" .. modpath)
  else
    vim.schedule(function()
      vim.notify("loadfile(" .. modname .. ")")
    end)
    chunk, err = loadfile(modpath)
    if chunk then
      Cache.set(modname, string.dump(chunk))
      M.hashes[modname] = M.hashes[modname] or Cache.hash(modpath)
    end
  end

  if chunk then
    ---@diagnostic disable-next-line: no-unknown
    package.loaded[modname] = chunk()
    return package.loaded[modname]
  else
    error(err)
  end
end

function M.setup()
  -- load cache
  local value = Cache.get("cache.modules")
  if value then
    M.hashes = vim.json.decode(value)
  end

  -- preload core modules
  local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
  for _, name in ipairs({ "util", "config", "loader", "state" }) do
    local modname = "lazy.core." .. name
    ---@diagnostic disable-next-line: no-unknown
    package.preload[modname] = function()
      return M.load(modname, root .. "/core/" .. name:gsub("%.", "/") .. ".lua")
    end
  end
  return M
end

function M.save()
  Cache.set("cache.modules", vim.json.encode(M.hashes))
end

return M
