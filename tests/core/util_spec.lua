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
        root = "lua/foo",
        mod = "foo",
        files = { "lua/foo/one.lua", "lua/foo/two.lua", "lua/foo/init.lua" },
        mods = { "foo.one", "foo.two", "foo" },
      },
      {
        root = "lua/foo",
        mod = "foo",
        files = { "lua/foo/one.lua", "lua/foo/two.lua", "lua/foo.lua" },
        mods = { "foo.one", "foo.two", "foo" },
      },
      {
        root = "lua/foo",
        mod = "foo",
        files = { "lua/foo/one.lua", "lua/foo/two.lua" },
        mods = { "foo.one", "foo.two" },
      },
      {
        root = "lua/load-plugins",
        mod = "load-plugins",
        files = { "lua/load-plugins.lua" },
        mods = { "load-plugins" },
      },
    }

    vim.opt.rtp:append(Helpers.path(""))
    for t, test in ipairs(tests) do
      local expected = vim.deepcopy(test.mods)
      table.sort(expected)
      Helpers.fs_rm("")
      local files = Helpers.fs_create(test.files)

      -- test with empty cache
      Cache.cache = {}
      Cache.indexed = {}
      Cache.indexed_rtp = false
      local root = Cache.find_root(test.mod)
      assert(root, "no root found for " .. test.mod .. " (test " .. t .. ")")
      assert.same(Helpers.path(test.root), root)
      local mods = {}
      Util.lsmod(test.mod, function(modname, modpath)
        mods[#mods + 1] = modname
      end)
      table.sort(mods)
      assert.same(expected, mods)

      -- fill the cache
      Cache.cache = {}
      for i, file in ipairs(files) do
        Cache.cache[test.mods[i]] = { modpath = file }
      end
      Cache.indexed = {}
      Cache.indexed_rtp = false
      root = Cache.find_root(test.mod)
      assert(root, "no root found for " .. test.mod .. " (test " .. t .. ")")
      assert.same(Helpers.path(test.root), root)
      mods = {}
      Util.lsmod(test.mod, function(modname, modpath)
        mods[#mods + 1] = modname
      end)
      table.sort(mods)
      assert.same(expected, mods)
    end
  end)
end)
