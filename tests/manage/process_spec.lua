local Async = require("lazy.async")
local Process = require("lazy.manage.process")

describe("process", function()
  it("runs sync", function()
    local lines = Process.exec({ "echo", "-n", "hello" })
    assert.are.same({ "hello" }, lines)
  end)

  it("runs sync from async context", function()
    local lines ---@type string[]
    local async = Async.new(function()
      lines = Process.exec({ "echo", "-n", "hello" })
    end)
    async:wait()

    assert.are.same({ "hello" }, lines)
  end)
end)
