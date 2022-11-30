local Config = require("lazy.core.config")
local Plugin = require("lazy.core.plugin")

local assert = require("luassert")

Config.setup()

describe("plugin spec uri/name", function()
  local tests = {
    { { "~/foo" }, { [1] = "~/foo", name = "foo", uri = vim.fn.fnamemodify("~/foo", ":p") } },
    { { "/tmp/foo" }, { [1] = "/tmp/foo", name = "foo", uri = "/tmp/foo" } },
    { { "foo/bar" }, { [1] = "foo/bar", name = "bar", uri = "https://github.com/foo/bar.git" } },
    { { "foo/bar", name = "foobar" }, { [1] = "foo/bar", name = "foobar", uri = "https://github.com/foo/bar.git" } },
    { { "foo/bar", uri = "123" }, { [1] = "foo/bar", name = "bar", uri = "123" } },
    { { "https://foobar" }, { [1] = "https://foobar", name = "foobar", uri = "https://foobar" } },
    { { "ssh://foobar" }, { [1] = "ssh://foobar", name = "foobar", uri = "ssh://foobar" } },
    { "foo/bar", { [1] = "foo/bar", name = "bar", uri = "https://github.com/foo/bar.git" } },
    { { { { "foo/bar" } } }, { [1] = "foo/bar", name = "bar", uri = "https://github.com/foo/bar.git" } },
  }

  for _, test in ipairs(tests) do
    it("parses " .. vim.inspect(test[1]):gsub("%s+", " "), function()
      local spec = Plugin.Spec.new(test[1])
      local plugins = vim.tbl_values(spec.plugins)
      assert.equal(1, #plugins)
      assert.same(test[2], plugins[1])
    end)
  end
end)

describe("plugin spec opt", function()
  it("handles dependencies", function()
    Config.options.defaults.opt = false
    local tests = {
      { "foo/bar", dependencies = { "foo/dep1", "foo/dep2" } },
      { "foo/bar", dependencies = { { "foo/dep1" }, "foo/dep2" } },
      { { { "foo/bar", dependencies = { { "foo/dep1" }, "foo/dep2" } } } },
    }
    for _, test in ipairs(tests) do
      local spec = Plugin.Spec.new(test)
      Config.plugins = spec.plugins
      Plugin.update_state()
      assert(vim.tbl_count(spec.plugins) == 3)
      assert(#spec.plugins.bar.dependencies == 2)
      assert(spec.plugins.bar.dep ~= true)
      assert(spec.plugins.bar.opt == false)
      assert(spec.plugins.dep1.dep == true)
      assert(spec.plugins.dep1.opt == true)
      assert(spec.plugins.dep2.dep == true)
      assert(spec.plugins.dep2.opt == true)
    end
  end)

  it("handles opt from dep", function()
    Config.options.defaults.opt = false
    local spec = Plugin.Spec.new({ "foo/dep1", { "foo/bar", dependencies = { "foo/dep1", "foo/dep2" } } })
    Config.plugins = spec.plugins
    Plugin.update_state()
    assert.same(3, vim.tbl_count(spec.plugins))
    assert(spec.plugins.bar.dep ~= true)
    assert(spec.plugins.bar.opt == false)
    assert(spec.plugins.dep2.dep == true)
    assert(spec.plugins.dep2.opt == true)
    assert(spec.plugins.dep1.dep ~= true)
    assert(spec.plugins.dep1.opt == false)
  end)

  it("handles defaults opt", function()
    do
      Config.options.defaults.opt = true
      local spec = Plugin.Spec.new({ "foo/bar" })
      Config.plugins = spec.plugins
      Plugin.update_state()
      assert(spec.plugins.bar.opt == true)
    end
    do
      Config.options.defaults.opt = false
      local spec = Plugin.Spec.new({ "foo/bar" })
      Config.plugins = spec.plugins
      Plugin.update_state()
      assert(spec.plugins.bar.opt == false)
    end
  end)

  it("handles opt from dep", function()
    Config.options.defaults.opt = false
    local spec = Plugin.Spec.new({ "foo/bar", module = "foo" })
    Config.plugins = spec.plugins
    Plugin.update_state()
    assert.same(1, vim.tbl_count(spec.plugins))
    assert(spec.plugins.bar.dep ~= true)
    assert(spec.plugins.bar.opt == true)
  end)

  it("merges lazy loaders", function()
    local tests = {
      { { "foo/bar", module = "mod1" }, { "foo/bar", module = "mod2" } },
      { { "foo/bar", module = { "mod1" } }, { "foo/bar", module = { "mod2" } } },
      { { "foo/bar", module = "mod1" }, { "foo/bar", module = { "mod2" } } },
    }
    for _, test in ipairs(tests) do
      local spec = Plugin.Spec.new(test)
      assert(vim.tbl_count(spec.plugins) == 1)
      assert(type(spec.plugins.bar.module) == "table")
      assert(#spec.plugins.bar.module == 2)
      assert(vim.tbl_contains(spec.plugins.bar.module, "mod1"))
      assert(vim.tbl_contains(spec.plugins.bar.module, "mod2"))
    end
  end)

  it("refuses to merge", function()
    assert.has.errors(function()
      Plugin.Spec.new({
        { "foo/dep1", config = 1 },
        {
          "foo/bar",
          dependencies = { { "foo/dep1", config = 2 }, "foo/dep2" },
        },
      })
    end)
  end)
end)
