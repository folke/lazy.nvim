local Util = require("lazy.util")
local Cache = require("lazy.core.cache")
local Helpers = require("tests.helpers")

describe("util", function()
  local rtp = vim.opt.rtp:get()
  before_each(function()
    vim.opt.rtp = rtp
    for k, v in pairs(package.loaded) do
      if k:find("^foobar") then
        package.loaded[k] = nil
      end
    end
    Helpers.fs_rm("")
    assert(not vim.loop.fs_stat(Helpers.path("")), "fs root should be deleted")
  end)

  it("lsmod lists all mods in dir", function()
    vim.opt.rtp:append(Helpers.path(""))
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

  it("find the correct root with dels", function()
    Cache.cache = {}
    Cache.indexed = {}
    Cache.indexed_rtp = false
    vim.opt.rtp:append(Helpers.path("old"))
    Helpers.fs_create({ "old/lua/foobar/init.lua" })
    Cache.cache["foobar"] = { modpath = Helpers.path("old/lua/foobar/init.lua") }
    local root = Cache.find_root("foobar")
    assert(root, "foobar root not found")
    assert.same(Helpers.path("old/lua/foobar"), root)

    Helpers.fs_rm("old")
    assert(not vim.loop.fs_stat(Helpers.path("old/lua/foobar")), "old/lua/foobar should not exist")

    -- vim.opt.rtp = rtp
    Cache.indexed = {}
    Cache.indexed_rtp = false
    vim.opt.rtp:append(Helpers.path("new"))
    Helpers.fs_create({ "new/lua/foobar/init.lua" })
    root = Cache.find_root("foobar")
    assert(root, "foobar root not found")
    assert.same(Helpers.path("new/lua/foobar"), root)
  end)

  it("find the correct root with mod dels", function()
    Cache.cache = {}
    Cache.indexed = {}
    Cache.indexed_rtp = false
    Cache.enabled = true
    vim.opt.rtp:append(Helpers.path("old"))
    Helpers.fs_create({ "old/lua/foobar/test.lua" })
    Cache.cache["foobar.test"] = { modpath = Helpers.path("old/lua/foobar/test.lua") }
    local root = Cache.find_root("foobar")
    assert(root, "foobar root not found")
    assert.same(Helpers.path("old/lua/foobar"), root)
    assert(not Cache.cache["foobar"], "foobar should not be in cache")
    assert(Cache.cache["foobar.test"], "foobar.test not found in cache")

    Helpers.fs_rm("old")

    -- vim.opt.rtp = rtp
    Cache.indexed = {}
    Cache.indexed_rtp = false
    vim.opt.rtp:append(Helpers.path("new"))
    Helpers.fs_create({ "new/lua/foobar/test.lua" })
    root = Cache.find_root("foobar")
    assert(root, "foobar root not found")
    assert.same(Helpers.path("new/lua/foobar"), root)
  end)

  it("merges correctly", function()
    local tests = {
      {
        input = { { a = 1 }, { b = 2 } },
        output = { a = 1, b = 2 },
      },
      {
        input = { { a = 1 }, { a = 2 } },
        output = { a = 2 },
      },
      {
        input = { { a = { 1, 2 } }, { a = { 3 } } },
        output = { a = { 3 } },
      },
      {
        input = { { b = { 1, 2 } }, { a = { 3 }, __merge = false } },
        output = { a = { 3 } },
      },
      {
        input = { { a = 1 }, { b = 2, __merge = false } },
        output = { b = 2 },
      },
      {
        input = { { a = { 1, 2 } }, { a = { 3, __merge = true } } },
        output = { a = { 1, 2, 3 } },
      },
      {
        input = { { a = { 1, 2, __merge = true } }, { a = { 3 } } },
        output = { a = { 1, 2, 3 } },
      },
      {
        input = { { a = { 1, 2, __merge = true } }, { a = { 3, __merge = false } } },
        output = { a = { 3 } },
      },
    }

    for _, test in ipairs(tests) do
      assert.same(test.output, Util.merge(unpack(test.input)))
    end
  end)
end)
