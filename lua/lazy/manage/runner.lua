local Task = require("lazy.manage.task")
local Config = require("lazy.core.config")

---@class RunnerOpts
---@field pipeline (string|{[1]:string, [string]:any})[]
---@field plugins? LazyPlugin[]|fun(plugin:LazyPlugin):any?

---@alias PipelineStep {task:string, opts?:TaskOptions}
---@alias LazyRunnerTask {co:thread, status: {task?:LazyTask, waiting?:boolean}}

---@class Runner
---@field _plugins LazyPlugin[]
---@field _running LazyRunnerTask[]
---@field _pipeline PipelineStep[]
---@field _on_done fun()[]
---@field _opts RunnerOpts
local Runner = {}

---@param opts RunnerOpts
function Runner.new(opts)
  local self = setmetatable({}, { __index = Runner })
  self._opts = opts or {}

  local plugins = self._opts.plugins
  if type(plugins) == "function" then
    self._plugins = vim.tbl_filter(plugins, Config.plugins)
  else
    self._plugins = plugins or Config.plugins
  end
  self._running = {}
  self._on_done = {}

  ---@param step string|(TaskOptions|{[1]:string})
  self._pipeline = vim.tbl_map(function(step)
    return type(step) == "string" and { task = step } or { task = step[1], opts = step }
  end, self._opts.pipeline)

  return self
end

---@param entry LazyRunnerTask
function Runner:_resume(entry)
  if entry.status.task and not entry.status.task:is_done() then
    return true
  end
  local ok, status = coroutine.resume(entry.co)
  entry.status = ok and status
  return entry.status ~= nil
end

function Runner:resume(waiting)
  local running = false
  for _, entry in ipairs(self._running) do
    if entry.status then
      if waiting and entry.status.waiting then
        entry.status.waiting = false
      end
      if not entry.status.waiting and self:_resume(entry) then
        running = true
      end
    end
  end
  return running or (not waiting and self:resume(true))
end

function Runner:start()
  for _, plugin in pairs(self._plugins) do
    local co = coroutine.create(self.run_pipeline)
    local ok, status = coroutine.resume(co, self, plugin)
    if ok then
      table.insert(self._running, { co = co, status = status })
    end
  end

  local check = vim.loop.new_check()
  check:start(function()
    if self:resume() then
      return
    end
    check:stop()
    self._running = {}
    for _, cb in ipairs(self._on_done) do
      vim.schedule(cb)
    end
    self._on_done = {}
  end)
end

---@async
---@param plugin LazyPlugin
function Runner:run_pipeline(plugin)
  for _, step in ipairs(self._pipeline) do
    if step.task == "wait" then
      coroutine.yield({ waiting = true })
    else
      local task = self:queue(plugin, step.task, step.opts)
      if task then
        coroutine.yield({ task = task })
        assert(task:is_done())
        if task.error then
          return
        end
      end
    end
  end
end

---@param plugin LazyPlugin
---@param task_type string
---@param task_opts? TaskOptions
---@return LazyTask?
function Runner:queue(plugin, task_type, task_opts)
  assert(self._running)
  local def = vim.split(task_type, ".", { plain = true })
  ---@type LazyTaskDef
  local task_def = require("lazy.manage.task." .. def[1])[def[2]]
  assert(task_def)
  if not (task_def.skip and task_def.skip(plugin, task_opts)) then
    local task = Task.new(plugin, def[2], task_def.run, task_opts)
    task:start()
    return task
  end
end

-- Execute the callback async when done.
-- When no callback is specified, this will wait sync
---@param cb? fun()
function Runner:wait(cb)
  if #self._running == 0 then
    return cb and cb()
  end

  if cb then
    table.insert(self._on_done, cb)
  else
    -- sync wait
    while #self._running > 0 do
      vim.wait(10)
    end
  end
end

return Runner
