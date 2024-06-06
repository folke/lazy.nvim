local Loader = require("lazy.core.loader")
local Util = require("lazy.core.util")

---@class LazyKeysBase
---@field desc? string
---@field noremap? boolean
---@field remap? boolean
---@field expr? boolean
---@field nowait? boolean
---@field ft? string|string[]

---@class LazyKeysSpec: LazyKeysBase
---@field [1] string lhs
---@field [2]? string|fun()|false rhs
---@field mode? string|string[]

---@class LazyKeys: LazyKeysBase
---@field lhs string lhs
---@field rhs? string|fun() rhs
---@field mode? string
---@field id string
---@field name string

---@class LazyKeysHandler:LazyHandler
local M = {}

local skip = { mode = true, id = true, ft = true, rhs = true, lhs = true }

---@param value string|LazyKeysSpec
---@param mode? string
---@return LazyKeys
function M.parse(value, mode)
  value = type(value) == "string" and { value } or value --[[@as LazyKeysSpec]]
  local ret = vim.deepcopy(value) --[[@as LazyKeys]]
  ret.lhs = ret[1] or ""
  ret.rhs = ret[2]
  ---@diagnostic disable-next-line: no-unknown
  ret[1] = nil
  ---@diagnostic disable-next-line: no-unknown
  ret[2] = nil
  ret.mode = mode or "n"
  ret.id = vim.api.nvim_replace_termcodes(ret.lhs, true, true, true)

  if ret.ft then
    local ft = type(ret.ft) == "string" and { ret.ft } or ret.ft --[[@as string[] ]]
    ret.id = ret.id .. " (" .. table.concat(ft, ", ") .. ")"
  end

  if ret.mode ~= "n" then
    ret.id = ret.id .. " (" .. ret.mode .. ")"
  end
  return ret
end

---@param keys LazyKeys
function M.to_string(keys)
  return keys.lhs .. (keys.mode == "n" and "" or " (" .. keys.mode .. ")")
end

---@param lhs string
---@param mode? string
function M:have(lhs, mode)
  local keys = M.parse(lhs, mode)
  return self.managed[keys.id] ~= nil
end

function M:_values(values)
  return M.resolve(values)
end

---@param spec? (string|LazyKeysSpec)[]
function M.resolve(spec)
  ---@type LazyKeys[]
  local values = {}
  ---@diagnostic disable-next-line: no-unknown
  for _, value in ipairs(spec or {}) do
    value = type(value) == "string" and { value } or value --[[@as LazyKeysSpec]]
    value.mode = value.mode or "n"
    local modes = (type(value.mode) == "table" and value.mode or { value.mode }) --[=[@as string[]]=]
    for _, mode in ipairs(modes) do
      local keys = M.parse(value, mode)
      if keys.rhs == vim.NIL or keys.rhs == false then
        values[keys.id] = nil
      else
        values[keys.id] = keys
      end
    end
  end
  return values
end

---@param keys LazyKeys
function M.opts(keys)
  local opts = {} ---@type LazyKeysBase
  ---@diagnostic disable-next-line: no-unknown
  for k, v in pairs(keys) do
    if type(k) ~= "number" and not skip[k] then
      ---@diagnostic disable-next-line: no-unknown
      opts[k] = v
    end
  end
  return opts
end

---@param keys LazyKeys
function M.is_nop(keys)
  return type(keys.rhs) == "string" and (keys.rhs == "" or keys.rhs:lower() == "<nop>")
end

---@param keys LazyKeys
function M:_add(keys)
  local lhs = keys.lhs
  local opts = M.opts(keys)

  ---@param buf? number
  local function add(buf)
    if M.is_nop(keys) then
      return self:_set(keys, buf)
    end

    vim.keymap.set(keys.mode, lhs, function()
      local plugins = self.active[keys.id]

      -- always delete the mapping immediately to prevent recursive mappings
      self:_del(keys)
      self.active[keys.id] = nil

      if plugins then
        local name = M.to_string(keys)
        Util.track({ keys = name })
        Loader.load(plugins, { keys = name })
        Util.track()
      end

      if keys.mode:sub(-1) == "a" then
        lhs = lhs .. "<C-]>"
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

  -- buffer-local mappings
  if keys.ft then
    vim.api.nvim_create_autocmd("FileType", {
      pattern = keys.ft,
      callback = function(event)
        if self.active[keys.id] and not M.is_nop(keys) then
          add(event.buf)
        else
          -- Only create the mapping if its managed by lazy
          -- otherwise the plugin is supposed to manage it
          self:_set(keys, event.buf)
        end
      end,
    })
  else
    add()
  end
end

-- Delete a mapping and create the real global/buffer-local
-- mapping when needed
---@param keys LazyKeys
function M:_del(keys)
  -- bufs will be all buffers of the filetype for a buffer-local mapping
  -- OR `false` for a global mapping
  local bufs = { false }

  if keys.ft then
    local ft = type(keys.ft) == "string" and { keys.ft } or keys.ft --[[@as string[] ]]
    bufs = vim.tbl_filter(function(buf)
      return vim.tbl_contains(ft, vim.bo[buf].filetype)
    end, vim.api.nvim_list_bufs())
  end

  for _, buf in ipairs(bufs) do
    pcall(vim.keymap.del, keys.mode, keys.lhs, { buffer = buf or nil })
    self:_set(keys, buf or nil)
  end
end

-- Create a mapping if it is managed by lazy
---@param keys LazyKeys
---@param buf number?
function M:_set(keys, buf)
  if keys.rhs then
    local opts = M.opts(keys)
    ---@diagnostic disable-next-line: inject-field
    opts.buffer = buf
    vim.keymap.set(keys.mode, keys.lhs, keys.rhs, opts)
  end
end

return M
