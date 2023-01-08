local Git = require("lazy.manage.git")

describe("lazy", function()
  before_each(function()
    vim.g.lazy_did_setup = false
    vim.go.loadplugins = true
    for modname in pairs(package.loaded) do
      if modname:find("lazy") == 1 then
        package.loaded[modname] = nil
      end
    end
  end)

  local root = ".tests/data/nvim/lazy"

  it("installs plugins", function()
    local Lazy = require("lazy")
    local Config = require("lazy.core.config")

    local neodev = false
    Lazy.setup({
      {
        "folke/neodev.nvim",
        config = function()
          neodev = true
        end,
      },
      "folke/paint.nvim",
    }, { install_missing = true, defaults = { lazy = true } })
    assert(3 == vim.tbl_count(Config.plugins))
    assert(vim.loop.fs_stat(root .. "/paint.nvim/README.md"))
    assert(vim.loop.fs_stat(root .. "/neodev.nvim/README.md"))
    assert(not neodev)
    assert(Config.plugins["neodev.nvim"]._.installed)
    assert(not Config.plugins["neodev.nvim"]._.is_local)
    assert.equal("https://github.com/folke/neodev.nvim.git", Git.get_origin(Config.plugins["neodev.nvim"].dir))
    assert.equal("https://github.com/folke/paint.nvim.git", Git.get_origin(Config.plugins["paint.nvim"].dir))
  end)
end)
