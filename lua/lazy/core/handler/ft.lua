local Event = require("lazy.core.handler.event")
local Util = require("lazy.core.util")
local Loader = require("lazy.core.loader")
local Config = require("lazy.core.config")

---@class LazyFiletypeHandler:LazyEventHandler
local M = {}
M.extends = Event

---@param value string
function M:_event(value)
  return "FileType " .. value
end

---@param plugin LazyPlugin
function M:add(plugin)
  self.super.add(self, plugin)
  if plugin.ft then
    Loader.ftdetect(plugin.dir)
  end
end

---@param pattern? string
function M:trigger(_, pattern, _)
  for _, group in ipairs({ "filetypeplugin", "filetypeindent" }) do
    Util.try(function()
      if Config.options.debug then
        Util.info({
          "# Firing Events",
          "  - **group:** `" .. group .. "`",
          "  - **event:** FileType",
          pattern and ("  - **pattern:** " .. pattern),
        })
      end
      vim.api.nvim_exec_autocmds("FileType", { group = group, modeline = false, pattern = pattern })
    end)
  end
end

return M
