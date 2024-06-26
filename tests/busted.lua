#!/usr/bin/env -S nvim -l

-- set stdpaths to use .tests
local root = vim.fn.fnamemodify("./.tests", ":p")
for _, name in ipairs({ "config", "data", "state", "cache" }) do
  vim.env[("XDG_%s_HOME"):format(name:upper())] = root .. "/" .. name
end

-- -- Bootstrap lazy.nvim
-- local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
-- if not (vim.uv or vim.loop).fs_stat(lazypath) then
--   local lazyrepo = "https://github.com/folke/lazy.nvim.git"
--   vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
-- end
-- vim.opt.rtp:prepend(lazypath)
vim.opt.rtp:prepend(".")

vim.o.loadplugins = true -- enable since nvim -l disables plugins

-- Setup lazy.nvim
require("lazy").setup({
  "lunarmodules/busted", -- add busted
})

-- run busted
return pcall(require("busted.runner"), {
  standalone = false,
}) or os.exit(1)
