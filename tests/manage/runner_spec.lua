local Runner = require("lazy.manage.runner")

describe("runner", function()
  local plugins = { { name = "plugin1", _ = {} }, { name = "plugin2", _ = {} } }

  ---@type {plugin:string, task:string}[]
  local runs = {}
  before_each(function()
    runs = {}
  end)

  package.loaded["lazy.manage.task.test"] = {}
  package.loaded["lazy.manage.task.test"]["skip"] = {
    skip = function()
      return true
    end,
  }
  for i = 1, 10 do
    package.loaded["lazy.manage.task.test"]["test" .. i] = {
      ---@param task LazyTask
      run = function(task)
        table.insert(runs, { plugin = task.plugin.name, task = task.type })
      end,
    }
    package.loaded["lazy.manage.task.test"]["error" .. i] = {
      ---@param task LazyTask
      run = function(task)
        table.insert(runs, { plugin = task.plugin.name, task = task.type })
        error("error" .. i)
      end,
    }
  end

  it("runs the pipeline", function()
    local runner = Runner.new({ plugins = plugins, pipeline = { "test.test1", "test.test2" } })
    runner:start()
    assert.equal(4, #runs)
  end)

  it("handles skips", function()
    local runner = Runner.new({ plugins = plugins, pipeline = { "test.test1", "test.skip", "test.test2" } })
    runner:start()
    assert.equal(4, #runs)
  end)

  it("aborts on error", function()
    local runner = Runner.new({ plugins = plugins, pipeline = { "test.test1", "test.error1", "test.test2" } })
    runner:start()
    assert.equal(4, #runs)
  end)
end)
