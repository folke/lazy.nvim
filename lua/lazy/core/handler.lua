local Util = require("lazy.core.util")
local Loader = require("lazy.core.loader")
local Config = require("lazy.core.config")

---@class LazyPluginHandlers
---@field event? string|string[]
---@field cmd? string|string[]
---@field ft? string|string[]
---@field keys? string|string[]

local M = {}

---@alias LazyHandler fun(grouped:table<string, string[]>)

function M.setup()
  for key, handler in pairs(M.handlers) do
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
    handler(group)
  end
end

---@param events string|string[]
---@param pattern? string
function M.get_augroups(events, pattern)
  -- Check for all autocmd groups listening for the events
  ---@type table<string,true>
  local groups = {}
  for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = events, pattern = pattern })) do
    if autocmd.group then
      groups[autocmd.group] = true
    end
  end
  return groups
end

---@param groups table<string,true>
---@param events string|string[]
---@param pattern? string
function M.trigger(groups, events, pattern)
  events = type(events) == "string" and { events } or events
  ---@cast events string[]
  for _, event in ipairs(events) do
    for _, autocmd in ipairs(vim.api.nvim_get_autocmds({ event = event, pattern = pattern })) do
      if autocmd.event == event and autocmd.group and not groups[autocmd.group] then
        if Config.options.debug then
          local lines = {
            "# Firing Events",
            "  - **event:** " .. autocmd.event,
            "  - **group:** `" .. autocmd.group_name .. "`",
          }
          if pattern then
            table.insert(lines, 2, "- **pattern:** " .. pattern)
          end
          Util.info(lines)
        end
        vim.api.nvim_exec_autocmds(autocmd.event, { group = autocmd.group, modeline = false })
      end
    end
  end
end

---@type table<string, LazyHandler>
M.handlers = {}
function M.handlers.event(grouped)
  local group = vim.api.nvim_create_augroup("lazy_handler_event", { clear = true })
  for event_spec, plugins in pairs(grouped) do
    if event_spec == "VeryLazy" then
      event_spec = "User VeryLazy"
    end
    if event_spec == "VimEnter" and vim.v.vim_did_enter == 1 then
      Loader.load(plugins, { event = event_spec })
    else
      local event, pattern = event_spec:match("^(%w+)%s+(.*)$")
      event = event or event_spec
      vim.api.nvim_create_autocmd(event, {
        group = group,
        once = true,
        pattern = pattern,
        callback = function()
          Util.track({ event = event_spec })
          local events = { event }
          if event == "BufRead" then
            events = { "BufReadPre", "BufRead" }
          elseif event == "BufReadPost" then
            events = { "BufReadPre", "BufRead", "BufReadPost" }
          end

          local groups = M.get_augroups(events, pattern)

          -- load the plugins
          Loader.load(plugins, { event = event_spec })

          -- check if any plugin created an event handler for this event and fire the group
          M.trigger(groups, events, pattern)
          Util.track()
        end,
      })
    end
  end
end

function M.handlers.keys(grouped)
  for keys, plugins in pairs(grouped) do
    vim.keymap.set("n", keys, function()
      vim.keymap.del("n", keys)
      Util.track({ keys = keys })
      Loader.load(plugins, { keys = keys })
      vim.api.nvim_input(keys)
      Util.track()
    end)
  end
end

function M.handlers.ft(grouped)
  local group = vim.api.nvim_create_augroup("lazy_handler_ft", { clear = true })
  for ft, plugins in pairs(grouped) do
    vim.api.nvim_create_autocmd("FileType", {
      once = true,
      pattern = ft,
      group = group,
      callback = function()
        Util.track({ ft = ft })
        local groups = M.get_augroups("FileType", ft)
        Loader.load(plugins, { ft = ft })
        M.trigger(groups, "FileType", ft)
        Util.track()
      end,
    })
  end
end

function M.handlers.cmd(grouped)
  for cmd, plugins in pairs(grouped) do
    local function _load()
      vim.api.nvim_del_user_command(cmd)
      Util.track({ cmd = cmd })
      Loader.load(plugins, { cmd = cmd })
      Util.track()
    end
    vim.api.nvim_create_user_command(cmd, function(event)
      _load()
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
        _load()
        -- HACK: trick Neovim to show the newly loaded command completion
        vim.api.nvim_input("<space><bs><tab>")
      end,
    })
  end
end

return M
