local Util = require("lazy.core.util")
local Loader = require("lazy.core.loader")

local M = {}

---@alias LazyHandler fun(plugins:LazyPlugin[])

---@param plugins LazyPlugin[]
---@param key string
---@return table<any, LazyPlugin[]>
function M.group(plugins, key)
  ---@type table<any, LazyPlugin[]>
  local ret = {}
  for _, plugin in pairs(plugins) do
    ---@diagnostic disable-next-line: no-unknown
    for _, value in pairs(type(plugin[key]) == "table" and plugin[key] or { plugin[key] }) do
      ret[value] = ret[value] or {}
      table.insert(ret[value], plugin)
    end
  end
  return ret
end

---@type table<string, LazyHandler>
M.handlers = {}

---@param plugins LazyPlugin[]
function M.handlers.event(plugins)
  local group = vim.api.nvim_create_augroup("lazy_handler_event", { clear = true })
  ---@diagnostic disable-next-line: redefined-local
  for event, plugins in pairs(M.group(plugins, "event")) do
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
          Util.track("event: " .. (_event == "User" and pattern or event))
          Loader.load(plugins, { event = event })
          Util.track()
        end,
      })
    end
  end
end

function M.handlers.keys(plugins)
  ---@diagnostic disable-next-line: redefined-local
  for keys, plugins in pairs(M.group(plugins, "keys")) do
    ---@cast keys string
    vim.keymap.set("n", keys, function()
      vim.keymap.del("n", keys)
      Util.track("keys: " .. keys)
      Loader.load(plugins, { keys = keys })
      vim.api.nvim_input(keys)
      Util.track()
    end)
  end
end

function M.handlers.ft(plugins)
  local group = vim.api.nvim_create_augroup("lazy_handler_ft", { clear = true })
  ---@diagnostic disable-next-line: redefined-local
  for ft, plugins in pairs(M.group(plugins, "ft")) do
    ---@cast ft string
    vim.api.nvim_create_autocmd("FileType", {
      once = true,
      pattern = ft,
      group = group,
      callback = function()
        Util.track("filetype: " .. ft)
        Loader.load(plugins, { ft = ft })
        Util.track()
      end,
    })
  end
end

function M.handlers.cmd(plugins)
  ---@diagnostic disable-next-line: redefined-local
  for cmd, plugins in pairs(M.group(plugins, "cmd")) do
    ---@cast cmd string
    local function _load(complete)
      vim.api.nvim_del_user_command(cmd)
      if complete then
        Util.track("cmd-complete: " .. cmd)
      else
        Util.track("cmd: " .. cmd)
      end
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
        _load(true)
        -- HACK: trick Neovim to show the newly loaded command completion
        vim.api.nvim_input("<space><bs><tab>")
      end,
    })
  end
end

function M.handlers.module(plugins)
  local modules = M.group(plugins, "module")
  ---@param modname string
  table.insert(package.loaders, 2, function(modname)
    local idx = modname:find(".", 1, true) or #modname + 1
    while idx do
      local name = modname:sub(1, idx - 1)
      ---@diagnostic disable-next-line: redefined-local
      local plugins = modules[name]
      if plugins then
        modules[name] = nil
        local reason = { require = modname }
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
