local Util = require("lazy.util")
local Cache = require("lazy.core.cache")
local Helpers = require("tests.helpers")

describe("util", function()
  before_each(function()
    Helpers.fs_rm("")
  end)

  it("lsmod lists all mods in dir", function()
    local tests = {
      {
        files = { "lua/foo/one.lua", "lua/foo/two.lua", "lua/foo/init.lua" },
        mods = { "foo", "foo.one", "foo.two" },
      },
      {
        files = { "lua/foo/one.lua", "lua/foo/two.lua", "lua/foo.lua" },
        mods = { "foo", "foo.one", "foo.two" },
      },
      {
        files = { "lua/foo/one.lua", "lua/foo/two.lua" },
        mods = { "foo.one", "foo.two" },
      },
    }

    vim.opt.rtp:append(Helpers.path(""))
    for _, test in ipairs(tests) do
      Cache.cache = {}
      table.sort(test.mods)
      Helpers.fs_rm("")
      Helpers.fs_create(test.files)
      local mods = {}
      Util.lsmod("foo", function(modname, modpath)
        mods[#mods + 1] = modname
      end)
      table.sort(mods)
      assert.same(test.mods, mods)
    end
  end)
end)
