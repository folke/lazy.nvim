local Async = require("lazy.async")
local Process = require("lazy.manage.process")

---@class LazyTaskDef
---@field skip? fun(plugin:LazyPlugin, opts?:TaskOptions):any?
---@field run fun(task:LazyTask, opts:TaskOptions)

---@alias LazyTaskFn async fun(task:LazyTask, opts:TaskOptions)

---@class LazyTask
---@field plugin LazyPlugin
---@field name string
---@field output string
---@field status string
---@field error? string
---@field warn? string
---@field private _started? number
---@field private _ended? number
---@field private _opts TaskOptions
---@field private _running Async
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
  self.plugin = plugin
  self.name = name
  self.output = ""
  self.status = ""
  ---@param other LazyTask
  plugin._.tasks = vim.tbl_filter(function(other)
    return other.name ~= name or other:is_running()
  end, plugin._.tasks or {})
  table.insert(plugin._.tasks, self)
  self:_start(task)
  return self
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
      self:notify_error(err)
    end,
    on_yield = function(res)
      self:notify(res)
    end,
  })
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

function Task:wait()
  while self:is_running() do
    vim.wait(10)
  end
end

return Task
