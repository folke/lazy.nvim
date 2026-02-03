#!/usr/bin/env -S nvim -l

vim.env.LAZY_STDPATH = ".tests"

vim.o.rtp = ".," .. vim.o.rtp

-- Setup lazy.nvim
require("lazy.minit").setup({
  spec = {
    { dir = vim.uv.cwd() },
  },
})
