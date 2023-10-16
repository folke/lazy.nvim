local Config = require("lazy.core.config")
local Loader = require("lazy.core.loader")
local Util = require("lazy.core.util")

---@class LazyEventOpts
---@field event string
---@field group? string
---@field exclude? string[]
---@field data? any
---@field buffer? number

---@alias LazyEvent {id:string, event:string[]|string, pattern?:string[]|string}
---@alias LazyEventSpec string|{event?:string|string[], pattern?:string|string[]}|string[]

---@class LazyEventHandler:LazyHandler
---@field events table<string,true>
---@field group number
local M = {}

-- Event dependencies
M.triggers = {
  FileType = "BufReadPost",
  BufReadPost = "BufReadPre",
}

-- A table of mappings for custom events
-- Can be used by distros to add custom events (see usage in LazyVim)
---@type table<string, LazyEvent>
M.mappings = {
  VeryLazy = { id = "VeryLazy", event = "User", pattern = "VeryLazy" },
  -- Example:
  -- LazyFile = { id = "LazyFile", event = { "BufReadPost", "BufNewFile", "BufWritePre" } },
}
M.mappings["User VeryLazy"] = M.mappings.VeryLazy

M.group = vim.api.nvim_create_augroup("lazy_handler_event", { clear = true })

---@param spec LazyEventSpec
---@return LazyEvent
function M:_parse(spec)
  local ret = M.mappings[spec] --[[@as LazyEvent?]]
  if ret then
    return ret
  end
  if type(spec) == "string" then
    local event, pattern = spec:match("^(%w+)%s+(.*)$")
    event = event or spec
    return { id = spec, event = event, pattern = pattern }
  elseif Util.is_list(spec) then
    ret = { id = table.concat(spec, "|"), event = spec }
  else
    ret = spec --[[@as LazyEvent]]
    if not ret.id then
      ---@diagnostic disable-next-line: assign-type-mismatch, param-type-mismatch
      ret.id = type(ret.event) == "string" and ret.event or table.concat(ret.event, "|")
      if ret.pattern then
        ---@diagnostic disable-next-line: assign-type-mismatch, param-type-mismatch
        ret.id = ret.id .. " " .. (type(ret.pattern) == "string" and ret.pattern or table.concat(ret.pattern, ", "))
      end
    end
  end
  return ret
end

---@param event LazyEvent
function M:_add(event)
  local done = false
  vim.api.nvim_create_autocmd(event.event, {
    group = self.group,
    once = true,
    pattern = event.pattern,
    callback = function(ev)
      if done or not self.active[event.id] then
        return
      end
      -- HACK: work-around for https://github.com/neovim/neovim/issues/25526
      done = true
      Util.track({ [self.type] = event.id })

      local state = M.get_state(ev.event, ev.buf, ev.data)

      -- load the plugins
      Loader.load(self.active[event.id], { [self.type] = event.id })

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
---@param buf number
---@param data any
function M.get_state(event, buf, data)
  local state = {} ---@type LazyEventOpts[]
  while event do
    table.insert(state, 1, {
      event = event,
      exclude = event ~= "FileType" and M.get_augroups(event) or nil,
      buffer = buf,
      data = data,
    })
    data = nil -- only pass the data to the first event
    event = M.triggers[event]
  end
  return state
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
      opts.group and ("  - **group:** " .. opts.group),
      opts.buffer and ("  - **buffer:** " .. opts.buffer),
    })
  end
  Util.track({ event = opts.group or opts.event })
  Util.try(function()
    vim.api.nvim_exec_autocmds(opts.event, {
      buffer = opts.buffer,
      group = opts.group,
      modeline = false,
      data = opts.data,
    })
    Util.track()
  end)
end

return M
