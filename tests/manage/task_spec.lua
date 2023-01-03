--# selene:allow(incorrect_standard_library_use)
local Task = require("lazy.manage.task")

describe("task", function()
  local plugin = { name = "test", _ = {} }

  local done = false
  ---@type string?
  local error

  local opts = {
    on_done = function(task)
      done = true
      error = task.error
    end,
  }

  before_each(function()
    done = false
    error = nil
  end)

  it("simple function", function()
    local task = Task.new(plugin, "test", function() end, opts)
    assert(not task:has_started())
    assert(not task:is_running())
    task:start()
    assert(not task:is_running())
    assert(task:is_done())
    assert(done)
  end)

  it("detects errors", function()
    local task = Task.new(plugin, "test", function()
      error("test")
    end, opts)
    assert(not task:has_started())
    assert(not task:is_running())
    task:start()
    assert(task:is_done())
    assert(not task:is_running())
    assert(done)
    assert(error)
    assert(task.error and task.error:find("test"))
  end)

  it("schedule", function()
    local running = false
    local task = Task.new(plugin, "test", function(task)
      running = true
      task:schedule(function()
        running = false
      end)
    end, opts)
    assert(not task:is_running())
    assert(not task:has_started())
    task:start()
    assert(running)
    assert(#task._running == 1)
    assert(task:is_running())
    assert(not task:is_done())
    task:wait()
    assert(task:is_done())
    assert(not task:is_running())
    assert(done)
    assert(not task.error)
  end)

  it("spawn errors", function()
    local task = Task.new(plugin, "test", function(task)
      task:spawn("foobar")
    end, opts)
    assert(not task:is_running())
    task:start()
    assert(not task:is_running())
    assert(done)
    assert(task.error and task.error:find("Failed to spawn"))
  end)

  it("spawn", function()
    local task = Task.new(plugin, "test", function(task)
      task:spawn("echo", { args = { "foo" } })
    end, opts)
    assert(not task:is_running())
    assert(not task:has_started())
    task:start()
    assert(task:has_started())
    assert(task:is_running())
    task:wait()
    assert(task:is_done())
    assert.same(task.output, "foo\n")
    assert(done)
    assert(not task.error)
  end)

  it("spawn 2x", function()
    local task = Task.new(plugin, "test", function(task)
      task:spawn("echo", { args = { "foo" } })
      task:spawn("echo", { args = { "bar" } })
    end, opts)
    assert(not task:is_running())
    task:start()
    assert(task:is_running())
    task:wait()
    assert(task.output == "foo\nbar\n" or task.output == "bar\nfoo\n")
    assert(done)
    assert(not task.error)
  end)
end)
