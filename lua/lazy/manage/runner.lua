---@class Runner
---@field _tasks LazyTask[]
local Runner = {}

function Runner.new()
  local self = setmetatable({}, {
    __index = Runner,
  })
  self._tasks = {}

  return self
end

---@param task LazyTask
function Runner:add(task)
  table.insert(self._tasks, task)
  task:start()
end

function Runner:is_empty()
  return #self._tasks == 0
end

---@return LazyPlugin[]
function Runner:plugins()
  ---@param task LazyTask
  return vim.tbl_map(function(task)
    return task.plugin
  end, self._tasks)
end

function Runner:tasks()
  return self._tasks
end

---@param cb? fun()
function Runner:wait(cb)
  if #self._tasks == 0 then
    return cb and cb()
  end

  local done = false
  local check = vim.loop.new_check()

  check:start(function()
    for _, task in ipairs(self._tasks) do
      if task.running then
        return
      end
    end

    check:stop()

    done = true

    if cb then
      vim.schedule(cb)
    end
  end)

  if not cb then
    while not done do
      vim.wait(100)
    end
  end
end

return Runner
