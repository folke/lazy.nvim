local Cache = require("lazy.core.cache")
local Helpers = require("tests.helpers")
local Util = require("lazy.util")

describe("util.parse_age", function()
  local cases = {
    { input = nil, expected = nil },
    { input = false, expected = nil },
    { input = 0, expected = nil },
    { input = 60, expected = 60 },
    { input = 3600, expected = 3600 },
    { input = "0d", expected = nil },
    { input = "30s", expected = 30 },
    { input = "30m", expected = 30 * 60 },
    { input = "24h", expected = 24 * 60 * 60 },
    { input = "7d", expected = 7 * 24 * 60 * 60 },
    { input = "2w", expected = 14 * 24 * 60 * 60 },
    { input = "1y", expected = 365 * 24 * 60 * 60 },
  }
  for _, case in ipairs(cases) do
    it("parses " .. vim.inspect(case.input), function()
      assert.equal(case.expected, Util.parse_age(case.input))
    end)
  end

  it("rejects invalid strings", function()
    -- silence the warn notification during the test
    local orig = vim.notify
    vim.notify = function() end
    assert.equal(nil, Util.parse_age("foo"))
    assert.equal(nil, Util.parse_age("7days"))
    assert.equal(nil, Util.parse_age("d"))
    assert.equal(nil, Util.parse_age(-5))
    assert.equal(nil, Util.parse_age(1.5))
    vim.notify = orig
  end)
end)

describe("util", function()
  local rtp = vim.opt.rtp:get()
  before_each(function()
    ---@type vim.Option
    vim.opt.rtp = rtp
    for k, v in pairs(package.loaded) do
      if k:find("^foobar") then
        package.loaded[k] = nil
      end
    end
    Helpers.fs_rm("")
    assert(not vim.uv.fs_stat(Helpers.path("")), "fs root should be deleted")
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

  it("find the correct root with dels", function()
    Cache.reset()
    vim.opt.rtp:append(Helpers.path("old"))
    Helpers.fs_create({ "old/lua/foobar/init.lua" })
    local root = Util.find_root("foobar")
    assert(root, "foobar root not found")
    assert.same(Helpers.path("old/lua/foobar"), root)

    Helpers.fs_rm("old")
    assert(not vim.uv.fs_stat(Helpers.path("old/lua/foobar")), "old/lua/foobar should not exist")

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
        input = { nil, { a = 1 }, { b = 2 } },
        output = { a = 1, b = 2 },
      },
      {
        input = { { a = 1 }, { b = 2 }, nil },
        output = { a = 1, b = 2 },
      },
      {
        input = { { a = 1 }, nil, { b = 2 } },
        output = { a = 1, b = 2 },
      },
      {
        input = { nil, { a = 1 }, nil, { b = 2 }, nil },
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
      local n = 0
      for i in pairs(test.input) do
        n = math.max(n, i)
      end
      assert.same(test.output, Util.merge(unpack(test.input, 1, n)))
    end
  end)
end)
