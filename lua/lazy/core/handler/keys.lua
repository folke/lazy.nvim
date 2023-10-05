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
---@field ft? string|string[]
---@field id string

---@class LazyKeysHandler:LazyHandler
local M = {}

---@param value string|LazyKeys
function M.parse(value)
  local ret = vim.deepcopy(value)
  ret = type(ret) == "string" and { ret } or ret --[[@as LazyKeys]]
  ret.mode = ret.mode or "n"
  ret.id = vim.api.nvim_replace_termcodes(ret[1] or "", true, true, true)
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
    if type(k) ~= "number" and k ~= "mode" and k ~= "id" and k ~= "ft" then
      opts[k] = v
    end
  end
  return opts
end

---@param keys LazyKeys
function M:_add(keys)
  local lhs = keys[1]
  local opts = M.opts(keys)

  ---@param buf? number
  local function add(buf)
    vim.keymap.set(keys.mode, lhs, function()
      local plugins = self.active[keys.id]

      -- always delete the mapping immediately to prevent recursive mappings
      self:_del(keys, buf)
      self.active[keys.id] = nil

      if plugins then
        Util.track({ keys = lhs })
        Loader.load(plugins, { keys = lhs })
        Util.track()
      end

      local feed = vim.api.nvim_replace_termcodes("<Ignore>" .. lhs, true, true, true)
      -- insert instead of append the lhs
      vim.api.nvim_feedkeys(feed, "i", false)
    end, {
      desc = opts.desc,
      nowait = opts.nowait,
      -- we do not return anything, but this is still needed to make operator pending mappings work
      expr = true,
      buffer = buf,
    })
  end

  if keys.ft then
    vim.api.nvim_create_autocmd("FileType", {
      pattern = keys.ft,
      callback = function(event)
        if self.active[keys.id] then
          add(event.buf)
        else
          -- Only create the mapping if its managed by lazy
          -- otherwise the plugin is supposed to manage it
          if keys[2] then
            self:_del(keys, event.buf)
          end
        end
      end,
    })
  else
    add()
  end
end

---@param keys LazyKeys
---@param buf number?
function M:_del(keys, buf)
  pcall(vim.keymap.del, keys.mode, keys[1], { buffer = buf })
  if keys[2] then
    local opts = M.opts(keys)
    opts.buffer = buf
    vim.keymap.set(keys.mode, keys[1], keys[2], opts)
  end
end

return M
