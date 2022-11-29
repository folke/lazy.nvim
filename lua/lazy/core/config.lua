local Util = require("lazy.core.util")

local M = {}

---@class LazyConfig
M.defaults = {
  opt = true,
  plugins = "config.plugins",
  plugins_local = {
    path = vim.fn.expand("~/projects"),
    ---@type string[]
    patterns = {},
  },
  interactive = true,
  packpath = vim.fn.stdpath("data") .. "/site/pack/lazy",
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json",
  view = {
    icons = {
      start = "",
      plugin = " ",
      source = " ",
      config = "",
      event = "",
      keys = " ",
      cmd = " ",
      ft = "",
      task = "✔ ",
    },
  },
}

M.ns = vim.api.nvim_create_namespace("lazy")

M.paths = {
  ---@type string
  main = nil,
  ---@type string
  plugins = nil,
}

---@type table<string, LazyPlugin>
M.plugins = {}

---@type LazyPlugin[]
M.to_clean = {}

---@type LazyConfig
M.options = {}

---@param opts? LazyConfig
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
  M.paths.plugins = vim.fn.stdpath("config") .. "/lua/" .. M.options.plugins:gsub("%.", "/")
  M.paths.main = M.paths.plugins .. (vim.loop.fs_stat(M.paths.plugins .. ".lua") and ".lua" or "/init.lua")

  -- TODO: check what this does inside a GUI. Probably still ok
  if #vim.api.nvim_list_uis() == 0 then
    M.options.interactive = false
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      require("lazy.view").setup()
    end,
  })

  Util.very_lazy()
end

return M
