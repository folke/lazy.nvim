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

---@param opts LazyEventOpts
function M:_trigger(opts)
  Util.try(function()
    if Config.options.debug then
      Util.info({
        "# Firing Events",
        "  - **event:** FileType",
        opts.pattern and ("  - **pattern:** " .. opts.pattern),
        opts.buf and ("  - **buf:** " .. opts.buf),
      })
    end
    Util.track({ event = "FileType" })
    vim.api.nvim_exec_autocmds("FileType", { modeline = false, buffer = opts.buf })
    Util.track()
  end)
end

return M
