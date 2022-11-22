local Util = require("lazy.core.util")

local M = {}

---@class LazyConfig
M.defaults = {
  opt = true,
  plugins = "config.plugins",
  plugins_local = {
    path = vim.fn.expand("~/projects"),
    patterns = {},
  },
  package_path = vim.fn.stdpath("data") .. "/site/pack/lazy",
}

M.ns = vim.api.nvim_create_namespace("lazy")

---@type table<string, LazyPlugin>
M.plugins = {}

---@type LazyConfig
M.options = {}

---@param opts? LazyConfig
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})

  -- vim.fn.mkdir(M.options.package_path, "p")

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
