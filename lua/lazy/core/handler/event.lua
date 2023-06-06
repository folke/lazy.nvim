local Util = require("lazy.core.util")
local Config = require("lazy.core.config")
local Loader = require("lazy.core.loader")

---@class LazyEventHandler:LazyHandler
---@field events table<string,true>
---@field group number
local M = {}

M.trigger_events = {
  BufRead = { "BufReadPre", "BufRead" },
  BufReadPost = { "BufReadPre", "BufRead", "BufReadPost" },
}
M.group = vim.api.nvim_create_augroup("lazy_handler_event", { clear = true })

---@param value string
function M:_add(value)
  local event_spec = self:_event(value)
  ---@type string?, string?
  local event, pattern = event_spec:match("^(%w+)%s+(.*)$")
  event = event or event_spec
  vim.api.nvim_create_autocmd(event, {
    group = self.group,
    once = true,
    pattern = pattern,
    callback = function()
      if not self.active[value] then
        return
      end
      Util.track({ [self.type] = value })
      local groups = M.get_augroups(event, pattern)
      -- load the plugins
      Loader.load(self.active[value], { [self.type] = value })
      -- check if any plugin created an event handler for this event and fire the group
      self:trigger(event, pattern, groups)
      Util.track()
    end,
  })
end

---@param value string
function M:_event(value)
  return value == "VeryLazy" and "User VeryLazy" or value
end

-- Get all augroups for the events
---@param event string
---@param pattern? string
function M.get_augroups(event, pattern)
  local events = M.trigger_events[event] or { event }
  ---@type table<string,true>
  local groups = {}
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = events, pattern = pattern })) do
    if autocmd.group then
      groups[autocmd.group] = true
    end
  end
  return groups
end

---@param event string|string[]
---@param pattern? string
---@param groups table<string,true>
function M:trigger(event, pattern, groups)
  local events = M.trigger_events[event] or { event }
  ---@cast events string[]
  for _, e in ipairs(events) do
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = e, pattern = pattern })) do
      if autocmd.event == e and autocmd.group and not groups[autocmd.group] then
        if Config.options.debug then
          Util.info({
            "# Firing Events",
            "  - **group:** `" .. autocmd.group_name .. "`",
            "  - **event:** " .. autocmd.event,
            pattern and ("  - **pattern:** " .. pattern),
          })
        end
        Util.track({ event = autocmd.group_name })
        Util.try(function()
          vim.api.nvim_exec_autocmds(autocmd.event, { group = autocmd.group, modeline = false })
          Util.track()
        end)
      end
    end
  end
end

return M
