local Util = require("lazy.core.util")
local Loader = require("lazy.core.loader")
local Config = require("lazy.core.config")

---@class LazyPluginHandlers
---@field event? string|string[]
---@field cmd? string|string[]
---@field ft? string|string[]
---@field module? string|string[]
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

---@type table<string, LazyHandler>
M.handlers = {}
function M.handlers.event(grouped)
  local group = vim.api.nvim_create_augroup("lazy_handler_event", { clear = true })
  for event, plugins in pairs(grouped) do
    ---@cast event string
    if event == "VimEnter" and vim.v.vim_did_enter == 1 then
      Loader.load(plugins, { event = event })
    else
      local _event, pattern = event:match("^(%w+)%s+(.*)$")
      vim.api.nvim_create_autocmd(_event or event, {
        group = group,
        once = true,
        pattern = pattern,
        callback = function()
          Util.track({ event = event })
          Loader.load(plugins, { event = event })
          Util.track()
        end,
      })
    end
  end
end

function M.handlers.keys(grouped)
  for keys, plugins in pairs(grouped) do
    ---@cast keys string
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
    ---@cast ft string
    vim.api.nvim_create_autocmd("FileType", {
      once = true,
      pattern = ft,
      group = group,
      callback = function()
        Util.track({ ft = ft })
        Loader.load(plugins, { ft = ft })
        Util.track()
      end,
    })
  end
end

function M.handlers.cmd(grouped)
  for cmd, plugins in pairs(grouped) do
    ---@cast cmd string
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

function M.handlers.module(grouped)
  ---@param modname string
  table.insert(package.loaders, 2, function(modname)
    local idx = modname:find(".", 1, true) or #modname + 1
    while idx do
      local name = modname:sub(1, idx - 1)
      ---@diagnostic disable-next-line: redefined-local
      local plugins = grouped[name]
      if plugins then
        grouped[name] = nil
        local reason = { require = modname }
        -- almost never happens, so this does not decrease performance
        if #Loader.loading == 0 then
          local f = 3
          while not reason.source do
            local info = debug.getinfo(f, "S")
            if not info then
              break
            end
            if info.what ~= "C" then
              reason.source = info.source:sub(2)
            end
            f = f + 1
          end
        end
        Loader.load(plugins, reason)
      end
      idx = modname:find(".", idx + 1, true)
    end
  end)
end

return M
