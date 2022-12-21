---
name: Bug report
about: Create a report to help us improve
title: ''
labels: bug
assignees: ''

---

**Describe the bug**
A clear and concise description of what the bug is.

**Which version of Neovim are you using?**
Gui(specify which GUI client you are using)? Nightly? Version?

**To Reproduce**
Make sure to read https://github.com/folke/lazy.nvim/wiki/Minimal-%60init.lua%60-to-Reproduce-an-Issue

Steps to reproduce the behavior:

1.
2.
3.

**Expected Behavior**
A clear and concise description of what you expected to happen.

**Screenshots**
If applicable, add screenshots to help explain your problem.

<details>
<summary>repro.lua</summary>

```lua
local root = vim.fn.fnamemodify("./.repro", ":p")

-- set stdpaths to use .repro
for _, name in ipairs({ "config", "data", "state", "cache" }) do
  vim.env[("XDG_%s_HOME"):format(name:upper())] = root .. "/" .. name
end

-- bootstrap lazy
local lazypath = root .. "/plugins/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end
vim.opt.runtimepath:prepend(lazypath)

-- install plugins
local plugins = {
  -- do not remove the colorscheme!
  "folke/tokyonight.nvim",
  -- add any other pugins here
}
require("lazy").setup(plugins, {
  root = root .. "/plugins",
})

-- add anything else here
vim.opt.termguicolors = true
-- do not remove the colorscheme!
vim.cmd([[colorscheme tokyonight]])
```

</details>

**Log**
Please include any related errors from the Noice log file. (open with `:Lazy log`)

<details>
<summary>Lazy log</summary>
<pre>
paste log here
</pre>
</details>
