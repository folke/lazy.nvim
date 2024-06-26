local Async = require("lazy.async")
local Config = require("lazy.core.config")
local Task = require("lazy.manage.task")

---@class RunnerOpts
---@field pipeline (string|{[1]:string, [string]:any})[]
---@field plugins? LazyPlugin[]|fun(plugin:LazyPlugin):any?
---@field concurrency? number

---@class RunnerTask
---@field task? LazyTask
---@field step number

---@alias PipelineStep {task:string, opts?:TaskOptions }

---@class Runner
---@field _plugins table<string,LazyPlugin>
---@field _pipeline PipelineStep[]
---@field _on_done fun()[]
---@field _opts RunnerOpts
---@field _running? Async
local Runner = {}

---@param opts RunnerOpts
function Runner.new(opts)
  local self = setmetatable({}, { __index = Runner })
  self._opts = opts or {}

  local plugins = self._opts.plugins
  ---@type LazyPlugin[]
  local pp = {}
  if type(plugins) == "function" then
    pp = vim.tbl_filter(plugins, Config.plugins)
  else
    pp = plugins or Config.plugins
  end
  self._plugins = {}
  for _, plugin in ipairs(pp) do
    self._plugins[plugin.name] = plugin
  end
  self._on_done = {}

  ---@param step string|(TaskOptions|{[1]:string})
  self._pipeline = vim.tbl_map(function(step)
    return type(step) == "string" and { task = step } or { task = step[1], opts = step }
  end, self._opts.pipeline)

  return self
end

function Runner:plugin(name)
  return self._plugins[name]
end

--- Update plugins
function Runner:update()
  for name in pairs(self._plugins) do
    self._plugins[name] = Config.plugins[name] or self._plugins[name]
  end
end

function Runner:start()
  ---@async
  self._running = Async.run(function()
    self:_start()
  end, {
    on_done = function()
      for _, cb in ipairs(self._on_done) do
        cb()
      end
    end,
  })
end

---@async
function Runner:_start()
  ---@type string[]
  local names = vim.tbl_keys(self._plugins)
  table.sort(names)

  ---@type table<string,RunnerTask>
  local state = {}

  local active = 1
  local waiting = 0
  ---@type number?
  local wait_step = nil

  ---@param resume? boolean
  local function continue(resume)
    active = 0
    waiting = 0
    wait_step = nil
    for _, name in ipairs(names) do
      state[name] = state[name] or { step = 0 }
      local s = state[name]
      local running = s.task and s.task:is_running()
      local step = self._pipeline[s.step]

      if s.task and s.task:has_errors() then
        local ignore = true
      elseif step and step.task == "wait" and not resume then
        waiting = waiting + 1
        wait_step = s.step
      elseif not running then
        if not self._opts.concurrency or active < self._opts.concurrency then
          local plugin = self:plugin(name)
          if s.step == #self._pipeline then
            s.task = nil
            plugin._.working = false
          elseif s.step < #self._pipeline then
            active = active + 1
            s.step = s.step + 1
            step = self._pipeline[s.step]
            if step.task == "wait" then
              plugin._.working = false
            else
              s.task = self:queue(plugin, step)
              plugin._.working = not not s.task
            end
          end
        end
      else
        active = active + 1
      end
    end
  end

  while active > 0 do
    continue()
    if active == 0 and waiting > 0 then
      local sync = self._pipeline[wait_step]
      if sync and sync.opts and type(sync.opts.sync) == "function" then
        sync.opts.sync(self)
      end
      continue(true)
    end
    coroutine.yield()
  end
end

---@param plugin LazyPlugin
---@param step PipelineStep
---@return LazyTask?
function Runner:queue(plugin, step)
  assert(self._running and self._running:running(), "Runner is not running")
  local def = vim.split(step.task, ".", { plain = true })
  ---@type LazyTaskDef
  local task_def = require("lazy.manage.task." .. def[1])[def[2]]
  assert(task_def, "Task not found: " .. step.task)
  local opts = step.opts or {}
  if not (task_def.skip and task_def.skip(plugin, opts)) then
    return Task.new(plugin, def[2], task_def.run, opts)
  end
end

function Runner:is_running()
  return self._running and self._running:running()
end

-- Execute the callback async when done.
-- When no callback is specified, this will wait sync
---@param cb? fun()
function Runner:wait(cb)
  if not self:is_running() then
    if cb then
      cb()
    end
    return self
  end

  if cb then
    table.insert(self._on_done, cb)
  else
    -- sync wait
    while self:is_running() do
      vim.wait(10)
    end
  end
  return self
end

return Runner
