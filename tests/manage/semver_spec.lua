local Semver = require("lazy.manage.semver")

local function v(version)
  return Semver.version(version)
end

describe("semver version", function()
  local tests = {
    ["v1.2.3"] = { major = 1, minor = 2, patch = 3 },
    ["v1.2"] = { major = 1, minor = 2, patch = 0 },
    ["v1.2.3-prerelease"] = { major = 1, minor = 2, patch = 3, prerelease = "prerelease" },
    ["v1.2-prerelease"] = { major = 1, minor = 2, patch = 0, prerelease = "prerelease" },
    ["v1.2.3-prerelease+build"] = { major = 1, minor = 2, patch = 3, prerelease = "prerelease", build = "build" },
    ["1.2.3+build"] = { major = 1, minor = 2, patch = 3, build = "build" },
  }
  for input, output in pairs(tests) do
    output.input = input
    it("correctly parses " .. input, function()
      assert.same(output, v(input))
    end)
  end
end)

describe("semver range", function()
  local tests = {
    ["1.2.3"] = { from = { 1, 2, 3 }, to = { 1, 2, 4 } },
    ["1.2"] = { from = { 1, 2, 0 }, to = { 1, 3, 0 } },
    ["=1.2.3"] = { from = { 1, 2, 3 }, to = { 1, 2, 4 } },
    [">1.2.3"] = { from = { 1, 2, 4 } },
    [">=1.2.3"] = { from = { 1, 2, 3 } },
    ["~1.2.3"] = { from = { 1, 2, 3 }, to = { 1, 3, 0 } },
    ["^1.2.3"] = { from = { 1, 2, 3 }, to = { 2, 0, 0 } },
    ["^0.2.3"] = { from = { 0, 2, 3 }, to = { 0, 3, 0 } },
    ["^0.0.1"] = { from = { 0, 0, 1 }, to = { 0, 0, 2 } },
    ["^1.2"] = { from = { 1, 2, 0 }, to = { 2, 0, 0 } },
    ["~1.2"] = { from = { 1, 2, 0 }, to = { 1, 3, 0 } },
    ["~1"] = { from = { 1, 0, 0 }, to = { 2, 0, 0 } },
    ["^1"] = { from = { 1, 0, 0 }, to = { 2, 0, 0 } },
    ["1.*"] = { from = { 1, 0, 0 }, to = { 2, 0, 0 } },
    ["1"] = { from = { 1, 0, 0 }, to = { 2, 0, 0 } },
    ["1.x"] = { from = { 1, 0, 0 }, to = { 2, 0, 0 } },
    ["1.2.x"] = { from = { 1, 2, 0 }, to = { 1, 3, 0 } },
    ["1.2.*"] = { from = { 1, 2, 0 }, to = { 1, 3, 0 } },
    ["*"] = { from = { 0, 0, 0 } },
    ["1.2 - 2.3.0"] = { from = { 1, 2, 0 }, to = { 2, 3, 0 } },
    ["1.2.3 - 2.3.4"] = { from = { 1, 2, 3 }, to = { 2, 3, 4 } },
    ["1.2.3 - 2"] = { from = { 1, 2, 3 }, to = { 3, 0, 0 } },
  }
  for input, output in pairs(tests) do
    output.from = v(output.from)
    output.to = output.to and v(output.to)

    local range = Semver.range(input)
    it("correctly parses " .. input, function()
      assert.same(output, range)
    end)

    it("from in range " .. input, function()
      assert(range:matches(output.from))
    end)

    it("from - 1 not in range " .. input, function()
      local lower = vim.deepcopy(range.from)
      lower.major = lower.major - 1
      assert(not range:matches(lower))
    end)

    it("to not in range " .. input .. " to:" .. tostring(range.to), function()
      if range.to then
        assert(not (range.to < range.to))
        assert(not range:matches(range.to))
      end
    end)
  end

  it("handles prereleass", function()
    assert(not Semver.range("1.2.3"):matches("1.2.3-alpha"))
    assert(Semver.range("1.2.3-alpha"):matches("1.2.3-alpha"))
    assert(not Semver.range("1.2.3-alpha"):matches("1.2.3-beta"))
  end)
end)

describe("semver order", function()
  it("is correct", function()
    assert(v("v1.2.3") == v("1.2.3"))
    assert(not (v("v1.2.3") < v("1.2.3")))
    assert(v("v1.2.3") > v("1.2.3-prerelease"))
    assert(v("v1.2.3-alpha") < v("1.2.3-beta"))
    assert(v("v1.2.3-prerelease") < v("1.2.3"))
    assert(v("v1.2.3") >= v("1.2.3"))
    assert(v("v1.2.3") >= v("1.0.3"))
    assert(v("v1.2.3") >= v("1.2.2"))
    assert(v("v1.2.3") > v("1.2.2"))
    assert(v("v1.2.3") > v("1.0.3"))
    assert.same(Semver.last({ v("1.2.3"), v("2.0.0") }), v("2.0.0"))
    assert.same(Semver.last({ v("2.0.0"), v("1.2.3") }), v("2.0.0"))
  end)
end)
