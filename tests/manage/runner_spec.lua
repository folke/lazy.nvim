local Runner = require("lazy.manage.runner")

describe("runner", function()
  local plugins = { { name = "plugin1" }, { name = "plugin2" } }

  ---@type {plugin:string, task:string}[]
  local runs = {}
  before_each(function()
    runs = {}
  end)

  package.loaded["lazy.manage.task.test"] = {}
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

  it("aborts on error", function()
    local runner = Runner.new({ plugins = plugins, pipeline = { "test.test1", "test.error1", "test.test2" } })
    runner:start()
    assert.equal(4, #runs)
  end)
end)
