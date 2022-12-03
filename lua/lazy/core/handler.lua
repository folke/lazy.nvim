local Util = require("lazy.core.util")
local Config = require("lazy.core.config")

---@class LazyPluginHandlers
---@field event? string|string[]
---@field cmd? string|string[]
---@field ft? string|string[]
---@field keys? string|string[]

local M = {}

---@enum LazyPluginHandlerTYpes
M.types = {
  keys = "keys",
  event = "event",
  cmd = "cmd",
  ft = "ft",
}

M.trigger_events = {
  BufRead = { "BufReadPre", "BufRead" },
  BufReadPost = { "BufReadPre", "BufRead", "BufReadPost" },
}

---@alias LazyHandler fun(grouped:table<string, string[]>)

function M.setup()
  M.cmd()
  M.event()
  M.ft()
  M.keys()
end

---@param key string
---@param fn fun(plugins:LazyPlugin[], value:string)
function M.foreach_group(key, fn)
  ---@type table<string, string[]>
  local group = {}
  for _, plugin in pairs(Config.plugins) do
    if plugin[key] then
      ---@diagnostic disable-next-line: no-unknown
      for _, value in pairs(type(plugin[key]) == "table" and plugin[key] or { plugin[key] }) do
        group[value] = group[value] or {}
        table.insert(group[value], plugin.name)
      end
    end
  end
  for value, plugins in pairs(group) do
    fn(plugins, value)
  end
end

---@param key string
---@param fn fun(plugin:LazyPlugin, value:string)
function M.foreach_value(key, fn)
  for _, plugin in pairs(Config.plugins) do
    ---@type string|string[]|nil
    local values = plugin[key]
    if values then
      if type(values) == "string" then
        fn(plugin, values)
      else
        for _, value in ipairs(values) do
          fn(plugin, value)
        end
      end
    end
  end
end

---@param plugin LazyPlugin
function M.cleanup(plugin)
  if plugin.keys then
    local keys = type(plugin.keys) == "string" and { plugin.keys } or plugin.keys
    ---@cast keys string[]
    for _, k in ipairs(keys) do
      pcall(vim.keymap.del, "n", k)
    end
  end

  if plugin.cmd then
    local cmd = type(plugin.cmd) == "string" and { plugin.cmd } or plugin.cmd
    ---@cast cmd string[]
    for _, c in ipairs(cmd) do
      pcall(vim.api.nvim_del_user_command, c)
    end
  end
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
function M.trigger(event, pattern, groups)
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
            pattern and "- **pattern:** ",
          })
        end
        Util.try(function()
          vim.api.nvim_exec_autocmds(autocmd.event, { group = autocmd.group, modeline = false })
        end)
      end
    end
  end
end

function M.event()
  local Loader = require("lazy.core.loader")
  local group = vim.api.nvim_create_augroup("lazy_handler_event", { clear = true })

  M.foreach_group("event", function(plugins, event_spec)
    event_spec = event_spec == "VeryLazy" and "User VeryLazy" or event_spec
    local event, pattern = event_spec:match("^(%w+)%s+(.*)$")
    event = event or event_spec
    vim.api.nvim_create_autocmd(event, {
      group = group,
      once = true,
      pattern = pattern,
      callback = function()
        Util.track({ event = event_spec })
        local groups = M.get_augroups(event, pattern)
        -- load the plugins
        Loader.load(plugins, { event = event_spec })
        -- check if any plugin created an event handler for this event and fire the group
        M.trigger(event, pattern, groups)
        Util.track()
      end,
    })
  end)
end

function M.keys()
  local Loader = require("lazy.core.loader")
  M.foreach_value("keys", function(plugin, keys)
    vim.keymap.set("n", keys, function()
      vim.keymap.del("n", keys)
      Util.track({ keys = keys })
      Loader.load(plugin, { keys = keys })
      vim.api.nvim_input(keys)
      Util.track()
    end)
  end)
end

function M.ft()
  local Loader = require("lazy.core.loader")
  local group = vim.api.nvim_create_augroup("lazy_handler_ft", { clear = true })
  M.foreach_group("ft", function(plugins, ft)
    vim.api.nvim_create_autocmd("FileType", {
      once = true,
      pattern = ft,
      group = group,
      callback = function()
        Util.track({ ft = ft })
        local groups = M.get_augroups("FileType", ft)
        Loader.load(plugins, { ft = ft })
        M.trigger("FileType", ft, groups)
        Util.track()
      end,
    })
  end)
end

function M.cmd()
  local Loader = require("lazy.core.loader")
  local function _load(plugin, cmd)
    vim.api.nvim_del_user_command(cmd)
    Util.track({ cmd = cmd })
    Loader.load(plugin, { cmd = cmd })
    Util.track()
  end

  M.foreach_value("cmd", function(plugin, cmd)
    vim.api.nvim_create_user_command(cmd, function(event)
      _load(plugin, cmd)
      vim.cmd(
        ("%s %s%s%s %s"):format(
          event.mods or "",
          event.line1 == event.line2 and "" or event.line1 .. "," .. event.line2,
          cmd,
          event.bang and "!" or "",
          event.args or ""
        )
      )
    end, {
      bang = true,
      nargs = "*",
      complete = function()
        _load(plugin, cmd)
        -- HACK: trick Neovim to show the newly loaded command completion
        vim.api.nvim_input("<space><bs><tab>")
      end,
    })
  end)
end

return M
