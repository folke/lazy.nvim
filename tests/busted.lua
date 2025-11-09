#!/usr/bin/env -S nvim -l

vim.env.LAZY_STDPATH = ".tests"
load(vim.fn.system("cat $(pwd)/bootstrap.lua"))()
--
-- -- Setup lazy.nvim
require("lazy.minit").busted({
  spec = {
    "LazyVim/starter",
    "williamboman/mason-lspconfig.nvim",
    "williamboman/mason.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
})
