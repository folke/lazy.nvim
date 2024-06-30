--# selene:allow(incorrect_standard_library_use)
local Async = require("lazy.async")
local Task = require("lazy.manage.task")

describe("task", function()
  local plugin = { name = "test", _ = {} }

  ---@type {done?:boolean, error:string?}
  local task_result = {}

  local opts = {
    ---@param task LazyTask
    on_done = function(task)
      task_result = { done = true, error = task.error }
    end,
  }

  before_each(function()
    task_result = {}
  end)

  it("simple function", function()
    local task = Task.new(plugin, "test", function() end, opts)
    assert(task:running())
    task:wait()
    assert(not task:running())
    assert(task_result.done)
  end)

  it("detects errors", function()
    local task = Task.new(plugin, "test", function()
      error("test")
    end, opts)
    assert(task:running())
    task:wait()
    assert(not task:running())
    assert(task_result.done)
    assert(task_result.error)
    assert(task:has_errors() and task:output(vim.log.levels.ERROR):find("test"))
  end)

  it("async", function()
    local running = true
    ---@async
    local task = Task.new(plugin, "test", function()
      Async.yield()
      running = false
    end, opts)
    assert(task:running())
    assert(running)
    assert(task:running())
    task:wait()
    assert(not running)
    assert(not task:running())
    assert(task_result.done)
    assert(not task:has_errors())
  end)

  it("spawn errors", function()
    local task = Task.new(plugin, "spawn_errors", function(task)
      task:spawn("foobar")
    end, opts)
    assert(task:running())
    task:wait()
    assert(not task:running())
    assert(task_result.done)
    assert(task:has_errors() and task:output(vim.log.levels.ERROR):find("Failed to spawn"), task:output())
  end)

  it("spawn", function()
    local task = Task.new(plugin, "test", function(task)
      task:spawn("echo", { args = { "foo" } })
    end, opts)
    assert(task:running())
    assert(task:running())
    task:wait()
    assert.same(task:output(), "foo")
    assert(task_result.done)
    assert(not task:has_errors())
  end)

  it("spawn 2x", function()
    local task = Task.new(plugin, "test", function(task)
      task:spawn("echo", { args = { "foo" } })
      task:spawn("echo", { args = { "bar" } })
    end, opts)
    assert(task:running())
    assert(task:running())
    task:wait()
    assert(task:output() == "foo\nbar" or task:output() == "bar\nfoo", task:output())
    assert(task_result.done)
    assert(not task:has_errors())
  end)
end)
