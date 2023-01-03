local Util = require("lazy.core.util")
local Loader = require("lazy.core.loader")

---@class LazyKeys
---@field [1] string lhs
---@field [2]? string|fun() rhs
---@field desc? string
---@field mode? string|string[]
---@field noremap? boolean
---@field remap? boolean
---@field expr? boolean

---@class LazyKeysHandler:LazyHandler
local M = {}

function M.retrigger(keys)
  local pending = ""
  while true do
    ---@type number|string
    local c = vim.fn.getchar(0)
    if c == 0 then
      break
    end
    c = type(c) == "number" and vim.fn.nr2char(c) or c
    pending = pending .. c
  end
  local op = vim.v.operator
  if op and op ~= "" and vim.api.nvim_get_mode().mode:find("o") then
    keys = "<esc>" .. op .. keys
  end
  local feed = vim.api.nvim_replace_termcodes(keys, true, true, true) .. pending
  if vim.v.count ~= 0 then
    feed = vim.v.count .. feed
  end
  vim.api.nvim_input(feed)
end

---@param value string|LazyKeys
function M.parse(value)
  local ret = vim.deepcopy(value)
  ret = type(ret) == "string" and { ret } or ret --[[@as LazyKeys]]
  ret.mode = ret.mode or "n"
  return ret
end

function M.opts(keys)
  local opts = {}
  for k, v in pairs(keys) do
    if type(k) ~= "number" and k ~= "mode" then
      opts[k] = v
    end
  end
  return opts
end

---@return string
function M:key(value)
  if type(value) == "string" then
    return value
  end
  local mode = value.mode or { "n" }
  if type(mode) == "string" then
    mode = { mode }
  end
  ---@type string
  local ret = value[1]
  if #mode > 0 then
    ret = table.concat(mode, ",") .. ": " .. ret
  end
  return ret
end

---@param value string|LazyKeys
function M:_add(value)
  local keys = M.parse(value)
  local lhs = keys[1]
  local opts = M.opts(keys)
  vim.keymap.set(keys.mode, lhs, function()
    local key = self:key(value)
    local plugins = self.active[key]

    -- always delete the mapping immediately to prevent recursive mappings
    self:_del(value)
    self.active[key] = nil

    Util.track({ keys = lhs })
    Loader.load(plugins, { keys = lhs })
    M.retrigger(lhs)
    Util.track()
  end, opts)
end

---@param value string|LazyKeys
function M:_del(value)
  local keys = M.parse(value)
  pcall(vim.keymap.del, keys.mode, keys[1])
  if keys[2] then
    vim.keymap.set(keys.mode, keys[1], keys[2], M.opts(keys))
  end
end

return M
