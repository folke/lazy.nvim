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
  self._running = Async.new(function()
    self:_start()
  end)
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

  ---@async
  ---@param resume? boolean
  local function continue(resume)
    active = 0
    waiting = 0
    wait_step = nil
    local next = {} ---@type string[]

    -- check running tasks
    for _, name in ipairs(names) do
      state[name] = state[name] or { step = 0 }
      local s = state[name]
      local is_running = s.task and s.task:running()
      local step = self._pipeline[s.step]

      if is_running then
        -- still running
        active = active + 1
      -- selene:allow(empty_if)
      elseif s.task and s.task:has_errors() then
        -- don't continue tasks if there are errors
      elseif step and step.task == "wait" and not resume then
        -- waiting for sync
        waiting = waiting + 1
        wait_step = s.step
      else
        next[#next + 1] = name
      end
    end

    -- schedule next tasks
    for _, name in ipairs(next) do
      if self._opts.concurrency and active >= self._opts.concurrency then
        break
      end
      local s = state[name]
      local plugin = self:plugin(name)
      while s.step <= #self._pipeline do
        if s.step == #self._pipeline then
          -- done
          s.task = nil
          plugin._.working = false
          break
        elseif s.step < #self._pipeline then
          -- next
          s.step = s.step + 1
          local step = self._pipeline[s.step]
          if step.task == "wait" then
            plugin._.working = false
            waiting = waiting + 1
            wait_step = s.step
            break
          else
            s.task = self:queue(plugin, step)
            plugin._.working = true
            if s.task then
              active = active + 1
              s.task:wake(false)
              break
            end
          end
        end
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
    if active > 0 then
      self._running:suspend()
    end
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
    self._running:on("done", cb)
  else
    self._running:wait()
  end
  return self
end

return Runner
