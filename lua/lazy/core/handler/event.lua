local Config = require("lazy.core.config")
local Loader = require("lazy.core.loader")
local Util = require("lazy.core.util")

---@class LazyEventOpts
---@field event string
---@field pattern? string
---@field group? string
---@field exclude? string[]
---@field data? any
---@field buffer? number

---@class LazyEventHandler:LazyHandler
---@field events table<string,true>
---@field group number
local M = {}

-- Event dependencies
M.triggers = {
  FileType = "BufReadPost",
  BufReadPost = "BufReadPre",
}

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

      local state = M.get_state(ev.event, pattern, ev.buf, ev.data)

      -- load the plugins
      Loader.load(self.active[value], { [self.type] = value })

      -- check if any plugin created an event handler for this event and fire the group
      for _, s in ipairs(state) do
        M.trigger(s)
      end
      Util.track()
    end,
  })
end

-- Get the current state of the event and all the events that will be fired
---@param event string
---@param pattern? string
---@param buf number
---@param data any
function M.get_state(event, pattern, buf, data)
  local state = {} ---@type LazyEventOpts[]
  while event do
    table.insert(state, 1, {
      event = event,
      pattern = pattern,
      exclude = event ~= "FileType" and M.get_augroups(event) or nil,
      buffer = buf,
      data = data,
    })
    data = nil -- only pass the data to the first event
    if event == "FileType" then
      pattern = nil -- only use the pattern for the first event
    end
    event = M.triggers[event]
  end
  return state
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
function M.get_augroups(event)
  local groups = {} ---@type string[]
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = event })) do
    if autocmd.group_name then
      table.insert(groups, autocmd.group_name)
    end
  end
  return groups
end

-- Trigger an event. When a group is given, only the events in that group will be triggered.
-- When exclude is set, the events in those groups will be skipped.
---@param opts LazyEventOpts
function M.trigger(opts)
  if opts.group or opts.exclude == nil then
    return M._trigger(opts)
  end
  local done = {} ---@type table<string,true>
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = opts.event })) do
    local id = autocmd.event .. ":" .. (autocmd.group or "") ---@type string
    local skip = done[id] or (opts.exclude and vim.tbl_contains(opts.exclude, autocmd.group_name))
    done[id] = true
    if autocmd.group and not skip then
      opts.group = autocmd.group_name
      M._trigger(opts)
    end
  end
end

-- Trigger an event
---@param opts LazyEventOpts
function M._trigger(opts)
  if Config.options.debug then
    Util.info({
      "# Firing Events",
      "  - **event:** " .. opts.event,
      opts.pattern and ("  - **pattern:** " .. opts.pattern),
      opts.group and ("  - **group:** " .. opts.group),
      opts.buffer and ("  - **buffer:** " .. opts.buffer),
    })
  end
  Util.track({ event = opts.group or opts.event })
  Util.try(function()
    vim.api.nvim_exec_autocmds(opts.event, {
      -- pattern = opts.pattern,
      buffer = opts.buffer,
      group = opts.group,
      modeline = false,
      data = opts.data,
    })
    Util.track()
  end)
end

return M
