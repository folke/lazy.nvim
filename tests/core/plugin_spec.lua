local Config = require("lazy.core.config")
local Plugin = require("lazy.core.plugin")

local assert = require("luassert")

Config.setup()

describe("plugin spec url/name", function()
  local tests = {
    { { "~/foo" }, { [1] = "~/foo", name = "foo", url = vim.fn.fnamemodify("~/foo", ":p") } },
    { { "/tmp/foo" }, { [1] = "/tmp/foo", name = "foo", url = "/tmp/foo" } },
    { { "foo/bar" }, { [1] = "foo/bar", name = "bar", url = "https://github.com/foo/bar.git" } },
    { { "foo/bar", name = "foobar" }, { [1] = "foo/bar", name = "foobar", url = "https://github.com/foo/bar.git" } },
    { { "foo/bar", url = "123" }, { [1] = "foo/bar", name = "bar", url = "123" } },
    { { "https://foobar" }, { [1] = "https://foobar", name = "foobar", url = "https://foobar" } },
    { { "ssh://foobar" }, { [1] = "ssh://foobar", name = "foobar", url = "ssh://foobar" } },
    { "foo/bar", { [1] = "foo/bar", name = "bar", url = "https://github.com/foo/bar.git" } },
    { { { { "foo/bar" } } }, { [1] = "foo/bar", name = "bar", url = "https://github.com/foo/bar.git" } },
  }

  for _, test in ipairs(tests) do
    test[2]._ = {}
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
    Config.options.defaults.lazy = false
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
      assert(spec.plugins.bar._.dep ~= true)
      assert(spec.plugins.bar.lazy == false)
      assert(spec.plugins.dep1._.dep == true)
      assert(spec.plugins.dep1.lazy == true)
      assert(spec.plugins.dep2._.dep == true)
      assert(spec.plugins.dep2.lazy == true)
    end
  end)

  it("handles opt from dep", function()
    Config.options.defaults.lazy = false
    local spec = Plugin.Spec.new({ "foo/dep1", { "foo/bar", dependencies = { "foo/dep1", "foo/dep2" } } })
    Config.plugins = spec.plugins
    Plugin.update_state()
    assert.same(3, vim.tbl_count(spec.plugins))
    assert(spec.plugins.bar._.dep ~= true)
    assert(spec.plugins.bar.lazy == false)
    assert(spec.plugins.dep2._.dep == true)
    assert(spec.plugins.dep2.lazy == true)
    assert(spec.plugins.dep1._.dep ~= true)
    assert(spec.plugins.dep1.lazy == false)
  end)

  it("handles defaults opt", function()
    do
      Config.options.defaults.lazy = true
      local spec = Plugin.Spec.new({ "foo/bar" })
      Config.plugins = spec.plugins
      Plugin.update_state()
      assert(spec.plugins.bar.lazy == true)
    end
    do
      Config.options.defaults.lazy = false
      local spec = Plugin.Spec.new({ "foo/bar" })
      Config.plugins = spec.plugins
      Plugin.update_state()
      assert(spec.plugins.bar.lazy == false)
    end
  end)

  it("handles opt from dep", function()
    Config.options.defaults.lazy = false
    local spec = Plugin.Spec.new({ "foo/bar", event = "foo" })
    Config.plugins = spec.plugins
    Plugin.update_state()
    assert.same(1, vim.tbl_count(spec.plugins))
    assert(spec.plugins.bar._.dep ~= true)
    assert(spec.plugins.bar.lazy == true)
  end)

  it("merges lazy loaders", function()
    local tests = {
      { { "foo/bar", event = "mod1" }, { "foo/bar", event = "mod2" } },
      { { "foo/bar", event = { "mod1" } }, { "foo/bar", event = { "mod2" } } },
      { { "foo/bar", event = "mod1" }, { "foo/bar", event = { "mod2" } } },
    }
    for _, test in ipairs(tests) do
      local spec = Plugin.Spec.new(test)
      assert(vim.tbl_count(spec.plugins) == 1)
      assert(type(spec.plugins.bar.event) == "table")
      assert(#spec.plugins.bar.event == 2)
      assert(vim.tbl_contains(spec.plugins.bar.event, "mod1"))
      assert(vim.tbl_contains(spec.plugins.bar.event, "mod2"))
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
