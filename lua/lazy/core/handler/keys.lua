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
    local c = vim.fn.getchar(0)
    if c == 0 then
      break
    end
    pending = pending .. vim.fn.nr2char(c)
  end
  local feed = vim.api.nvim_replace_termcodes(keys .. pending, true, true, true)
  vim.api.nvim_feedkeys(feed, "m", false)
end

---@param value string|LazyKeys
function M.parse(value)
  local ret = vim.deepcopy(value)
  ret = (type(ret) == "string" and { ret } or ret) --[[@as LazyKeys]]
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

---@param value string|LazyKeys
function M:_add(value)
  local keys = M.parse(value)
  local lhs = keys[1]
  local opts = M.opts(keys)
  opts.noremap = false
  vim.keymap.set(keys.mode, lhs, function()
    Util.track({ keys = lhs })
    self:_del(value)
    Loader.load(self.active[value], { keys = lhs })
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
