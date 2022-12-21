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
    local extra = ""
    while true do
      local c = vim.fn.getchar(0)
      if c == 0 then
        break
      end
      extra = extra .. vim.fn.nr2char(c)
    end
    local feed = vim.api.nvim_replace_termcodes(keys .. extra, true, true, true)
    vim.api.nvim_feedkeys(feed, "m", false)
    Util.track()
  end, { silent = true })
end

---@param keys string
function M:_del(keys)
  pcall(vim.keymap.del, "n", keys)
end

return M
