local Async = require("lazy.async")
local Process = require("lazy.manage.process")

---@class LazyTaskDef
---@field skip? fun(plugin:LazyPlugin, opts?:TaskOptions):any?
---@field run async fun(task:LazyTask, opts:TaskOptions)

---@alias LazyTaskFn async fun(task:LazyTask, opts:TaskOptions)

---@class LazyMsg
---@field msg string
---@field level? number

---@class LazyTask
---@field plugin LazyPlugin
---@field name string
---@field private _log LazyMsg[]
---@field private _started? number
---@field private _ended? number
---@field private _opts TaskOptions
---@field private _running Async
---@field private _level number
local Task = {}

---@class TaskOptions: {[string]:any}
---@field on_done? fun(task:LazyTask)

---@param plugin LazyPlugin
---@param name string
---@param opts? TaskOptions
---@param task LazyTaskFn
function Task.new(plugin, name, task, opts)
  local self = setmetatable({}, { __index = Task })
  self._opts = opts or {}
  self._log = {}
  self._level = vim.log.levels.TRACE
  self.plugin = plugin
  self.name = name
  ---@param other LazyTask
  plugin._.tasks = vim.tbl_filter(function(other)
    return other.name ~= name or other:is_running()
  end, plugin._.tasks or {})
  table.insert(plugin._.tasks, self)
  self:_start(task)
  return self
end

---@param level? number
---@return LazyMsg[]
function Task:get_log(level)
  level = level or vim.log.levels.DEBUG
  return vim.tbl_filter(function(msg)
    return msg.level >= level
  end, self._log)
end

---@param level? number
function Task:output(level)
  return table.concat(
    ---@param m LazyMsg
    vim.tbl_map(function(m)
      return m.msg
    end, self:get_log(level)),
    "\n"
  )
end

function Task:status()
  local ret = self._log[#self._log]
  return ret and ret.msg or ""
end

function Task:has_started()
  return self._started ~= nil
end

function Task:has_ended()
  return self._ended ~= nil
end

function Task:is_running()
  return not self:has_ended()
end

function Task:has_errors()
  return self._level >= vim.log.levels.ERROR
end

function Task:has_warnings()
  return self._level >= vim.log.levels.WARN
end

---@private
---@param task LazyTaskFn
function Task:_start(task)
  assert(not self:has_started(), "task already started")
  assert(not self:has_ended(), "task already done")

  self._started = vim.uv.hrtime()
  ---@async
  self._running = Async.run(function()
    task(self, self._opts)
  end, {
    on_done = function()
      self:_done()
    end,
    on_error = function(err)
      self:error(err)
    end,
    on_yield = function(res)
      self:log(res)
    end,
  })
end

---@param msg string|string[]
---@param level? number
function Task:log(msg, level)
  level = level or vim.log.levels.DEBUG
  self._level = math.max(self._level or 0, level or 0)
  msg = type(msg) == "table" and table.concat(msg, "\n") or msg
  ---@cast msg string
  table.insert(self._log, { msg = msg, level = level })
  vim.api.nvim_exec_autocmds("User", { pattern = "LazyRender", modeline = false })
end

---@param msg string|string[]
function Task:error(msg)
  self:log(msg, vim.log.levels.ERROR)
end

---@param msg string|string[]
function Task:warn(msg)
  self:log(msg, vim.log.levels.WARN)
end

---@private
function Task:_done()
  assert(self:has_started(), "task not started")
  assert(not self:has_ended(), "task already done")

  if self._running and self._running:running() then
    return
  end

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
    self:log(line, vim.log.levels.TRACE)
    if on_line then
      pcall(on_line, line)
    end
  end

  local running = true
  ---@param output string
  function opts.on_exit(ok, output)
    self:log(vim.trim(output), ok and vim.log.levels.DEBUG or vim.log.levels.ERROR)
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

function Task:wait()
  while self:is_running() do
    vim.wait(10)
  end
end

return Task
