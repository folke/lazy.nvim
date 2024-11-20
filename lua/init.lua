-- DO NOT change the paths and don't remove the colorscheme
local root = vim.fn.fnamemodify("./.nvim", ":p")

-- set stdpaths to use .repro
for _, name in ipairs({ "config", "data", "state", "cache" }) do
  vim.env[("XDG_%s_HOME"):format(name:upper())] = root .. "/" .. name
end

local lazy_dev = vim.fn.expand("~/projects/lazy.nvim")
if vim.uv.fs_stat(lazy_dev) then
  vim.opt.runtimepath:prepend(lazy_dev)
else
  -- bootstrap lazy
  local lazypath = root .. "/plugins/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    print("Bootstrapping lazy.nvim")
    vim.fn.system({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      lazypath,
    })
  end
  vim.opt.runtimepath:prepend(lazypath)
end

local function main()
  print("Installing plugins")
  require("lazy").setup({
    spec = {
      { "folke/lazy.nvim" },
      "folke/tokyonight.nvim",
    },
    root = root .. "/plugins",
  })

  if vim.o.filetype == "lazy" then
    vim.cmd.close()
  end

  print("Updating plugins")
  -- update plugins, wait for it to finish and don't show the output
  require("lazy").update({ wait = true, show = false })
  -- require("lazy.core.cache").reset()

  vim.opt.rtp:append(".")

  print("Building docs")

  require("build").update()

  print("Done!\n")
end

local Util = require("lazy.core.util")
Util.try(main, {
  on_error = function(err)
    print(err)
    os.exit(1)
  end,
})
os.exit(0)
