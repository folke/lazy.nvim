describe("init", function()
  it("has correct environment for tests", function()
    for _, path in ipairs({ "config", "data", "cache", "state" }) do
      assert(vim.fn.stdpath(path):find(".tests/" .. path))
    end
  end)
end)
