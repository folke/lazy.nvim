local Task = require("lazy.manage.task")
local Config = require("lazy.core.config")

---@alias LazyPipeline TaskType[]

---@class RunnerOpts
---@field pipeline LazyPipeline
---@field interactive? boolean
---@field plugins? LazyPlugin[]|fun(plugin:LazyPlugin):any?

---@class Runner
---@field _tasks LazyTask[]
---@field _plugins LazyPlugin[]
---@field _running boolean
---@field _on_done fun()[]
---@field _waiting fun()[]
---@field _opts RunnerOpts
local Runner = {}

---@param opts RunnerOpts
function Runner.new(opts)
  local self = setmetatable({}, { __index = Runner })
  self._opts = opts or {}
  self._tasks = {}

  local plugins = self._opts.plugins
  if type(plugins) == "function" then
    self._plugins = vim.tbl_filter(plugins, Config.plugins)
  else
    self._plugins = plugins or Config.plugins
  end
  self._running = false
  self._on_done = {}
  self._waiting = {}
  return self
end

---@param plugin LazyPlugin
---@param pipeline LazyPipeline
function Runner:_run(plugin, pipeline)
  ---@type TaskType
  local op = table.remove(pipeline, 1)
  if op == "wait" then
    return table.insert(self._waiting, function()
      self:_run(plugin, pipeline)
    end)
  end
  self:queue(plugin, op, function(task)
    if not (task and task.error) and #pipeline > 0 then
      self:_run(plugin, pipeline)
    end
  end)
end

---@param plugin LazyPlugin
---@param task_type TaskType
---@param on_done fun(task?:LazyTask)
---@return LazyTask?
function Runner:queue(plugin, task_type, on_done)
  local def = vim.split(task_type, ".", { plain = true })
  assert(#def == 2)
  ---@type LazyTaskDef
  local task_def = require("lazy.manage.task." .. def[1])[def[2]]
  assert(task_def)
  if not (task_def.skip and task_def.skip(plugin, self._opts)) then
    local task = Task.new(plugin, def[2], task_def.run, { on_done = on_done })
    table.insert(self._tasks, task)
    task:start()
  else
    on_done()
  end
end

function Runner:start()
  for _, plugin in pairs(self._plugins) do
    self:_run(plugin, vim.deepcopy(self._opts.pipeline))
  end
  self._running = true
  local check = vim.loop.new_check()

  check:start(function()
    for _, task in ipairs(self._tasks) do
      if task:is_running() then
        return
      end
    end
    if #self._waiting > 0 then
      local waiting = self._waiting
      self._waiting = {}
      for _, cb in ipairs(waiting) do
        cb()
      end
      return
    end
    check:stop()
    self._running = false
    for _, cb in ipairs(self._on_done) do
      vim.schedule(cb)
    end
    self._on_done = {}
  end)
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

-- Execute the callback async when done.
-- When no callback is specified, this will wait sync
---@param cb? fun()
function Runner:wait(cb)
  if #self._tasks == 0 or not self._running then
    return cb and cb()
  end

  if cb then
    table.insert(self._on_done, cb)
  else
    -- sync wait
    while self._running do
      vim.wait(100)
    end
  end
end

return Runner
