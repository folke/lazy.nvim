#!/usr/bin/env -S nvim -l

vim.opt.rtp:prepend(".")

-- Setup lazy.nvim
require("lazy.minit").busted({
  spec = {},
  stdpath = ".tests",
})
