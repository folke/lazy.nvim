local Config = require("lazy.core.config")
local Plugin = require("lazy.core.plugin")

local assert = require("luassert")

Config.setup()

describe("plugin spec", function()
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
    it("parses uri " .. vim.inspect(test[1]):gsub("%s+", " "), function()
      local spec = Plugin.Spec.new(test[1])
      local plugins = vim.tbl_values(spec.plugins)
      assert.equal(1, #plugins)
      assert.same(test[2], plugins[1])
    end)
  end
end)
