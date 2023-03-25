local Util = require("lazy.core.util")
local Loader = require("lazy.core.loader")

---@class LazyKeys
---@field [1] string lhs
---@field [2]? string|fun()|false rhs
---@field desc? string
---@field mode? string|string[]
---@field noremap? boolean
---@field remap? boolean
---@field expr? boolean
---@field id string

---@class LazyKeysHandler:LazyHandler
local M = {}

---@param value string|LazyKeys
function M.parse(value)
  local ret = vim.deepcopy(value)
  ret = type(ret) == "string" and { ret } or ret --[[@as LazyKeys]]
  ret.mode = ret.mode or "n"
  ret.id = (ret[1] or "")
  if ret.mode then
    local mode = ret.mode
    if type(mode) == "table" then
      ---@cast mode string[]
      table.sort(mode)
      mode = table.concat(mode, ", ")
    end
    if mode ~= "n" then
      ret.id = ret.id .. " (" .. mode .. ")"
    end
  end
  return ret
end

---@param plugin LazyPlugin
function M:values(plugin)
  ---@type table<string,any>
  local values = {}
  ---@diagnostic disable-next-line: no-unknown
  for _, value in ipairs(plugin[self.type] or {}) do
    local keys = M.parse(value)
    if keys[2] == vim.NIL or keys[2] == false then
      values[keys.id] = nil
    else
      values[keys.id] = keys
    end
  end
  return values
end

function M.opts(keys)
  local opts = {}
  for k, v in pairs(keys) do
    if type(k) ~= "number" and k ~= "mode" and k ~= "id" then
      opts[k] = v
    end
  end
  return opts
end

---@param keys LazyKeys
function M:_add(keys)
  local lhs = keys[1]
  local opts = M.opts(keys)
  vim.keymap.set(keys.mode, lhs, function()
    local plugins = self.active[keys.id]

    -- always delete the mapping immediately to prevent recursive mappings
    self:_del(keys)
    self.active[keys.id] = nil

    Util.track({ keys = lhs })
    Loader.load(plugins, { keys = lhs })
    Util.track()

    local feed = vim.api.nvim_replace_termcodes("<Ignore>" .. lhs, true, true, true)
    -- insert instead of append the lhs
    vim.api.nvim_feedkeys(feed, "i", false)
  end, {
    desc = opts.desc,
    nowait = opts.nowait,
    -- we do not return anything, but this is still needed to make operator pending mappings work
    expr = true,
  })
end

---@param keys LazyKeys
function M:_del(keys)
  pcall(vim.keymap.del, keys.mode, keys[1])
  if keys[2] then
    vim.keymap.set(keys.mode, keys[1], keys[2], M.opts(keys))
  end
end

return M
