local Util = require("lazy.util")

local M = {}

---@class LazyConfig
M.defaults = {
  opt = true,
  plugins = {},
  plugins_local = {
    path = vim.fn.expand("~/projects"),
    patterns = {
      "folke",
    },
  },
  plugins_config = {
    module = "plugins",
    path = vim.fn.stdpath("config") .. "/lua/plugins",
  },
  package_path = vim.fn.stdpath("data") .. "/site/pack/lazy",
}

M.ns = vim.api.nvim_create_namespace("lazy")

---@type table<string, LazyPlugin>
M.plugins = {}

---@type LazyConfig
M.options = {}

---@type table<string, string>
M.has_config = {}

---@param opts? LazyConfig
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})

  vim.fn.mkdir(M.options.package_path, "p")

  for _, entry in ipairs(Util.scandir(M.options.plugins_config.path)) do
    local name, modpath

    if entry.type == "file" then
      modpath = entry.path
      name = entry.name:match("(.*)%.lua")
    elseif entry.type == "directory" then
      modpath = M.options.plugins_config.path .. "/" .. entry.name .. "/init.lua"
      if vim.loop.fs_stat(modpath) then
        name = entry.name
      end
    end

    if name then
      M.has_config[M.options.plugins_config.module .. "." .. name] = modpath
    end
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      -- require("lazy.view").setup()
    end,
  })

  Util.very_lazy()
end

return M
