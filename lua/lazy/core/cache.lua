-- Simple string cache with fast saving and loading from file
local M = {}

M.dirty = false

local cache_path = vim.fn.stdpath("state") .. "/lazy.state"
---@type string
local cache_hash = ""
---@type table<string,boolean>
local used = {}
---@type table<string,string>
local cache = {}

---@return string?
function M.get(key)
  if cache[key] then
    used[key] = true
    return cache[key]
  end
end

function M.debug()
  local ret = {}
  for key, value in pairs(cache) do
    ret[key] = #value
  end
  return ret
end

function M.set(key, value)
  cache[key] = value
  used[key] = true
  M.dirty = true
end

function M.del(key)
  cache[key] = nil
  M.dirty = true
end

function M.hash(file)
  local stat = vim.loop.fs_stat(file)
  return stat and (stat.mtime.sec .. stat.mtime.nsec .. stat.size)
end

function M.setup()
  cache = {}
  local f = io.open(cache_path, "rb")
  if f then
    cache_hash = M.hash(cache_path)
    ---@type string
    local data = f:read("*a")
    f:close()

    local from = 1
    local to = data:find("\0", from, true)
    while to do
      local key = data:sub(from, to - 1)
      from = to + 1
      to = data:find("\0", from, true)
      local len = tonumber(data:sub(from, to - 1))
      from = to + 1
      cache[key] = data:sub(from, from + len - 1)
      from = from + len
      to = data:find("\0", from, true)
    end
  end
end

function M.autosave()
  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyDone",
    once = true,
    callback = function()
      vim.api.nvim_create_autocmd("VimLeavePre", {
        callback = function()
          if M.dirty then
            local hash = M.hash(cache_path)
            -- abort when the file was changed in the meantime
            if hash == nil or cache_hash == hash then
              M.save()
            end
          end
        end,
      })
    end,
  })
end

function M.save()
  require("lazy.core.plugin").save()
  require("lazy.core.module").save()

  local f = assert(io.open(cache_path, "wb"))
  for key, value in pairs(cache) do
    if used[key] then
      f:write(key, "\0", tostring(#value), "\0", value)
    end
  end
  f:close()
end

return M
