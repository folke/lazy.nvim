local Util = require("lazy.core.util")

describe("init", function()
  it("has correct environment for tests", function()
    for _, name in ipairs({ "config", "data", "cache", "state" }) do
      local path = Util.norm(vim.fn.stdpath(name) --[[@as string]])
      assert(path:find(".tests/" .. name, 1, true), path .. " not in .tests")
    end
  end)
end)
