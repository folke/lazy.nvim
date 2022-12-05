local Util = require("lazy.core.util")
local Loader = require("lazy.core.loader")

---@class LazyKeysHandler:LazyHandler
local M = {}

---@param plugin LazyPlugin
---@param keys string
function M:_add(plugin, keys)
  vim.keymap.set("n", keys, function()
    vim.keymap.del("n", keys)
    Util.track({ keys = keys })
    Loader.load(plugin, { keys = keys })
    vim.api.nvim_input(keys)
    Util.track()
  end)
end

---@param _plugin LazyPlugin
---@param value string
function M:_del(_plugin, value)
  pcall(vim.keymap.del, "n", value)
end

return M
