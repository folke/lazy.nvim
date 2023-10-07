local Util = require("lazy.core.util")
local Config = require("lazy.core.config")
local Loader = require("lazy.core.loader")

---@class LazyEventOpts
---@field event string
---@field pattern? string
---@field exclude? string[]
---@field data? any
---@field buf? number}

---@class LazyEventHandler:LazyHandler
---@field events table<string,true>
---@field group number
local M = {}

M.group = vim.api.nvim_create_augroup("lazy_handler_event", { clear = true })

---@param value string
function M:_add(value)
  local event_spec = self:_event(value)
  ---@type string?, string?
  local event, pattern = event_spec:match("^(%w+)%s+(.*)$")
  event = event or event_spec
  local done = false
  vim.api.nvim_create_autocmd(event, {
    group = self.group,
    once = true,
    pattern = pattern,
    callback = function(ev)
      if done or not self.active[value] then
        return
      end
      done = true
      Util.track({ [self.type] = value })
      local groups = M.get_augroups(ev.event, pattern)
      -- load the plugins
      Loader.load(self.active[value], { [self.type] = value })
      -- check if any plugin created an event handler for this event and fire the group
      self:_trigger({
        event = ev.event,
        pattern = pattern,
        exclude = groups,
        data = ev.data,
        buf = ev.buf,
      })
      Util.track()
    end,
  })
end

---@param value string
function M:_event(value)
  if value == "VeryLazy" then
    return "User VeryLazy"
  elseif value == "BufRead" then
    return "BufReadPost"
  end
  return value
end

-- Get all augroups for the events
---@param event string
---@param pattern? string
function M.get_augroups(event, pattern)
  local groups = {} ---@type string[]
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = event, pattern = pattern })) do
    if autocmd.group_name then
      table.insert(groups, autocmd.group_name)
    end
  end
  return groups
end

---@param opts LazyEventOpts
function M:_trigger(opts)
  M.trigger(opts)
end

---@param opts LazyEventOpts
function M.trigger(opts)
  local done = {} ---@type table<string,true>
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = opts.event, pattern = opts.pattern })) do
    local id = autocmd.event .. ":" .. (autocmd.group or "") ---@type string
    local skip = done[id] or (opts.exclude and vim.tbl_contains(opts.exclude, autocmd.group_name))
    done[id] = true
    if autocmd.group and not skip then
      if Config.options.debug then
        Util.info({
          "# Firing Events",
          "  - **group:** `" .. autocmd.group_name .. "`",
          "  - **event:** " .. autocmd.event,
          opts.pattern and ("  - **pattern:** " .. opts.pattern),
          opts.buf and ("  - **buf:** " .. opts.buf),
        })
      end
      Util.track({ event = autocmd.group_name })
      Util.try(function()
        vim.api.nvim_exec_autocmds(autocmd.event, {
          -- pattern = opts.pattern,
          buffer = opts.buf,
          group = autocmd.group,
          modeline = false,
          data = opts.data,
        })
        Util.track()
      end)
    end
  end
end

return M
