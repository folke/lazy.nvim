local Util = require("lazy.core.util")
local Loader = require("lazy.core.loader")

---@class LazyKeysHandler:LazyHandler
local M = {}

---@param keys string
function M:_add(keys)
  vim.keymap.set("n", keys, function()
    vim.keymap.del("n", keys)
    Util.track({ keys = keys })
    Loader.load(self.active[keys], { keys = keys })
    local feed = vim.api.nvim_replace_termcodes(keys, true, false, true)
    vim.api.nvim_feedkeys(feed, "m", false)
    Util.track()
  end, { silent = true })
end

---@param keys string
function M:_del(keys)
  pcall(vim.keymap.del, "n", keys)
end

return M
