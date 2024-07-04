#!/usr/bin/env -S nvim -l

vim.env.LAZY_STDPATH = ".tests"

vim.opt.rtp:prepend(".")

-- Setup lazy.nvim
require("lazy.minit").setup({
  spec = {
    { dir = vim.uv.cwd() },
  },
})
