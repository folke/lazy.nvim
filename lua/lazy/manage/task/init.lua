local Process = require("lazy.manage.process")

---@class LazyTaskDef
---@field skip? fun(plugin:LazyPlugin, opts?:TaskOptions):any?
---@field run fun(task:LazyTask, opts:TaskOptions)

---@alias LazyTaskState {task:LazyTask, thread:thread}

local Scheduler = {}
---@type LazyTaskState[]
Scheduler._queue = {}
Scheduler._executor = assert(vim.loop.new_check())
Scheduler._running = false

function Scheduler.step()
  Scheduler._running = true
  local budget = 1 * 1e6
  local start = vim.loop.hrtime()
  local count = #Scheduler._queue
  local i = 0
  while #Scheduler._queue > 0 and vim.loop.hrtime() - start < budget do
    ---@type LazyTaskState
    local state = table.remove(Scheduler._queue, 1)
    state.task:_step(state.thread)
    if coroutine.status(state.thread) ~= "dead" then
      table.insert(Scheduler._queue, state)
    end
    i = i + 1
    if i >= count then
      break
    end
  end
  Scheduler._running = false
  if #Scheduler._queue == 0 then
    return Scheduler._executor:stop()
  end
end

---@param state LazyTaskState
function Scheduler.add(state)
  table.insert(Scheduler._queue, state)
  if not Scheduler._executor:is_active() then
    Scheduler._executor:start(vim.schedule_wrap(Scheduler.step))
  end
end

---@class LazyTask
---@field plugin LazyPlugin
---@field name string
---@field output string
---@field status string
---@field error? string
---@field warn? string
---@field private _task fun(task:LazyTask, opts:TaskOptions)
---@field private _started? number
---@field private _ended? number
---@field private _opts TaskOptions
---@field private _threads thread[]
local Task = {}

---@class TaskOptions: {[string]:any}
---@field on_done? fun(task:LazyTask)

---@param plugin LazyPlugin
---@param name string
---@param opts? TaskOptions
---@param task fun(task:LazyTask)
function Task.new(plugin, name, task, opts)
  local self = setmetatable({}, {
    __index = Task,
  })
  self._opts = opts or {}
  self._threads = {}
  self._task = task
  self._started = nil
  self.plugin = plugin
  self.name = name
  self.output = ""
  self.status = ""
  ---@param other LazyTask
  plugin._.tasks = vim.tbl_filter(function(other)
    return other.name ~= name or other:is_running()
  end, plugin._.tasks or {})
  table.insert(plugin._.tasks, self)
  return self
end

function Task:has_started()
  return self._started ~= nil
end

function Task:has_ended()
  return self._ended ~= nil
end

function Task:is_done()
  return self:has_started() and self:has_ended()
end

function Task:is_running()
  return self:has_started() and not self:has_ended()
end

function Task:start()
  assert(not self:has_started(), "task already started")
  assert(not self:has_ended(), "task already done")

  self._started = vim.uv.hrtime()
  self:async(function()
    self._task(self, self._opts)
  end)
end

---@param msg string|string[]
---@param severity? vim.diagnostic.Severity
function Task:notify(msg, severity)
  local var = severity == vim.diagnostic.severity.ERROR and "error"
    or severity == vim.diagnostic.severity.WARN and "warn"
    or "output"
  msg = type(msg) == "table" and table.concat(msg, "\n") or msg
  ---@cast msg string
  ---@diagnostic disable-next-line: no-unknown
  self[var] = self[var] and (self[var] .. "\n" .. msg) or msg
  self.status = msg
  vim.api.nvim_exec_autocmds("User", { pattern = "LazyRender", modeline = false })
end

---@param msg string|string[]
function Task:notify_error(msg)
  self:notify(msg, vim.diagnostic.severity.ERROR)
end

---@param msg string|string[]
function Task:notify_warn(msg)
  self:notify(msg, vim.diagnostic.severity.WARN)
end

---@param fn async fun()
function Task:async(fn)
  local co = coroutine.create(fn)
  table.insert(self._threads, co)
  Scheduler.add({ task = self, thread = co })
end

---@param co thread
function Task:_step(co)
  local status = coroutine.status(co)
  if status == "suspended" then
    local ok, res = coroutine.resume(co)
    if not ok then
      self:notify_error(tostring(res))
    elseif res then
      self:notify(tostring(res))
    end
  end
  for _, t in ipairs(self._threads) do
    if coroutine.status(t) ~= "dead" then
      return
    end
  end
  self:_done()
end

---@private
function Task:_done()
  assert(self:has_started(), "task not started")
  assert(not self:has_ended(), "task already done")
  self._ended = vim.uv.hrtime()
  if self._opts.on_done then
    self._opts.on_done(self)
  end
  vim.api.nvim_exec_autocmds("User", { pattern = "LazyRender", modeline = false })
  vim.api.nvim_exec_autocmds("User", {
    pattern = "LazyPlugin" .. self.name:sub(1, 1):upper() .. self.name:sub(2),
    data = { plugin = self.plugin.name },
  })
end

function Task:time()
  if not self:has_started() then
    return 0
  end
  if not self:has_ended() then
    return (vim.uv.hrtime() - self._started) / 1e6
  end
  return (self._ended - self._started) / 1e6
end

---@async
---@param cmd string
---@param opts? ProcessOpts
function Task:spawn(cmd, opts)
  opts = opts or {}
  local on_line = opts.on_line
  local on_exit = opts.on_exit

  function opts.on_line(line)
    self.status = line
    if on_line then
      pcall(on_line, line)
    end
    vim.api.nvim_exec_autocmds("User", { pattern = "LazyRender", modeline = false })
  end

  local running = true
  ---@param output string
  function opts.on_exit(ok, output)
    self.output = self.output .. output
    if not ok then
      self.error = self.error and (self.error .. "\n" .. output) or output
    end
    if on_exit then
      pcall(on_exit, ok, output)
    end
    running = false
  end
  Process.spawn(cmd, opts)
  while running do
    coroutine.yield()
  end
end

---@param tasks (LazyTask?)[]
function Task.all_done(tasks)
  for _, task in ipairs(tasks) do
    if task and not task:is_done() then
      return false
    end
  end
  return true
end

function Task:wait()
  while self:is_running() do
    vim.wait(10)
  end
end

return Task
