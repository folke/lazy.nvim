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

  it("find_roots lists the expected single root", function()
    vim.opt.rtp:append(Helpers.path(""))

    local tests = {
      {
        root = "lua/foo",
        mod = "foo",
        files = { "lua/foo/one.lua", "lua/foo/two.lua", "lua/foo/init.lua" },
      },
      {
        root = "lua/foo",
        mod = "foo",
        files = { "lua/foo/one.lua", "lua/foo/two.lua", "lua/foo.lua" },
      },
      {
        root = "lua/foo",
        mod = "foo",
        files = { "lua/foo/one.lua", "lua/foo/two.lua" },
      },
      {
        root = "lua/load-plugins",
        mod = "load-plugins",
        files = { "lua/load-plugins.lua" },
      },
    }

    for t, test in ipairs(tests) do
      Helpers.fs_rm("")
      assert(not vim.loop.fs_stat(Helpers.path("")), "fs root should be deleted")

      local files = Helpers.fs_create(test.files)

      Cache.reset()
      local roots = Util.find_roots(test.mod)
      assert.equal(#roots, 1, "wrong number of roots found for " .. test.mod .. " (test " .. t .. ")")

      local expected_root = Helpers.path(test.root)
      assert.same({expected_root}, roots, "wrong roots found (test " .. t .. ")")
    end
  end)

  it("find_roots lists the correct multiple roots", function()
    vim.opt.rtp:append(Helpers.path("first"))
    vim.opt.rtp:append(Helpers.path("second"))

    local tests = {
      {
        roots = { "first/lua/foo", "second/lua/foo" },
        mod = "foo",
        files = { "first/lua/foo/init.lua", "second/lua/foo/local.lua" },
      },
      {
        roots = { "first/lua/foo", "second/lua/foo" },
        mod = "foo",
        files = { "first/lua/foo.lua", "second/lua/foo/baz.lua" },
      },
    }

    for t, test in ipairs(tests) do
      Helpers.fs_rm("")
      assert(not vim.loop.fs_stat(Helpers.path("")), "fs root should be deleted")

      local files = Helpers.fs_create(test.files)

      Cache.reset()
      local roots = Util.find_roots(test.mod)
      assert(#roots > 0, "no roots found for " .. test.mod .. " (test " .. t .. ")")

      local expected_roots = {}
      for _, root in ipairs(test.roots) do
        expected_roots[#expected_roots + 1] = Helpers.path(root)
      end
      assert.same(expected_roots, roots)
    end
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
      Cache.reset()
      local root = Util.find_root(test.mod)
      assert(root, "no root found for " .. test.mod .. " (test " .. t .. ")")
      assert.same(Helpers.path(test.root), root)
      local mods = {}
      Util.lsmod(test.mod, function(modname, modpath)
        mods[#mods + 1] = modname
      end)
      table.sort(mods)
      assert.same(expected, mods)

      -- fill the cache
      Cache.reset()
      root = Util.find_root(test.mod)
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

  it("lsmod lists modules in multiple roots", function()
    vim.opt.rtp:append(Helpers.path("first"))
    vim.opt.rtp:append(Helpers.path("second"))

    local tests = {
      {
        roots = { "first/lua/foo", "second/lua/foo" },
        mod = "foo",
        files = { "first/lua/foo/init.lua", "second/lua/foo/local.lua" },
        mods = { "foo", "foo.local" },
      },
      {
        roots = { "first/lua/foo", "second/lua/foo" },
        mod = "foo",
        files = { "first/lua/foo.lua", "second/lua/foo/baz.lua" },
        mods = { "foo", "foo.baz" },
      },
    }

    for t, test in ipairs(tests) do
      Helpers.fs_rm("")
      assert(not vim.loop.fs_stat(Helpers.path("")), "fs root should be deleted")

      local files = Helpers.fs_create(test.files)

      Cache.reset()
      local roots = Util.find_roots(test.mod)
      assert(#roots > 0, "no roots found for " .. test.mod .. " (test " .. t .. ")")

      local expected_roots = {}
      for _, root in ipairs(test.roots) do
        expected_roots[#expected_roots + 1] = Helpers.path(root)
      end
      assert.same(expected_roots, roots)

      mods = {}
      Util.lsmod(test.mod, function(modname, modpath)
        mods[#mods + 1] = modname
      end)
      table.sort(mods)
      assert.same(test.mods, mods)
    end
  end)

  it("find the correct root with dels", function()
    Cache.reset()
    vim.opt.rtp:append(Helpers.path("old"))
    Helpers.fs_create({ "old/lua/foobar/init.lua" })
    local root = Util.find_root("foobar")
    assert(root, "foobar root not found")
    assert.same(Helpers.path("old/lua/foobar"), root)

    Helpers.fs_rm("old")
    assert(not vim.loop.fs_stat(Helpers.path("old/lua/foobar")), "old/lua/foobar should not exist")

    -- vim.opt.rtp = rtp
    vim.opt.rtp:append(Helpers.path("new"))
    Helpers.fs_create({ "new/lua/foobar/init.lua" })
    root = Util.find_root("foobar")
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
        input = { { b = { 1, 2 } }, { a = { 3 }, b = vim.NIL } },
        output = { a = { 3 } },
      },
      {
        input = { { a = 1 }, { b = 2, a = vim.NIL } },
        output = { b = 2 },
      },
    }

    for _, test in ipairs(tests) do
      assert.same(test.output, Util.merge(unpack(test.input)))
    end
  end)
end)
