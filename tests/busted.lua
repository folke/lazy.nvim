#!/usr/bin/env -S nvim -l

-- set stdpaths to use .tests
local root = vim.fn.fnamemodify("./.tests", ":p")
for _, name in ipairs({ "config", "data", "state", "cache" }) do
  vim.env[("XDG_%s_HOME"):format(name:upper())] = root .. "/" .. name
end

vim.opt.rtp:prepend(".")

vim.o.loadplugins = true -- enable since nvim -l disables plugins

-- Setup lazy.nvim
require("lazy").setup({
  spec = {
    "lunarmodules/busted", -- add busted
  },
  rocks = { hererocks = true },
})

local Config = require("lazy.core.config")
-- disable termnial output for the tests
Config.options.headless = {}

-- run busted
return pcall(require("busted.runner"), {
  standalone = false,
}) or os.exit(1)
