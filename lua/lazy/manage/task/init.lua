local Process = require("lazy.manage.process")

---@class LazyTaskDef
---@field skip? fun(plugin:LazyPlugin, opts?:TaskOptions):any?
---@field run fun(task:LazyTask, opts:TaskOptions)

---@alias LazyTaskState fun():boolean?

---@class LazyTask
---@field plugin LazyPlugin
---@field name string
---@field output string
---@field status string
---@field error? string
---@field private _task fun(task:LazyTask)
---@field private _running LazyPluginState[]
---@field private _started? number
---@field private _ended? number
---@field private _opts TaskOptions
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
  self._running = {}
  self._task = task
  self._started = nil
  self.plugin = plugin
  self.name = name
  self.output = ""
  self.status = ""
  plugin._.tasks = plugin._.tasks or {}
  ---@param other LazyTask
  plugin._.tasks = vim.tbl_filter(function(other)
    return other.name ~= name or other:is_running()
  end, plugin._.tasks)
  table.insert(plugin._.tasks, self)
  return self
end

function Task:has_started()
  return self._started ~= nil
end

function Task:is_done()
  return self:has_started() and not self:is_running()
end

function Task:is_running()
  return self:has_started() and self._ended == nil
end

function Task:start()
  if vim.in_fast_event() then
    return vim.schedule(function()
      self:start()
    end)
  end
  self._started = vim.loop.hrtime()
  ---@type boolean, string|any
  local ok, err = pcall(self._task, self, self._opts)
  if not ok then
    self.error = err or "failed"
  end
  self:_check()
end

---@private
function Task:_check()
  for _, state in ipairs(self._running) do
    if state() then
      return
    end
  end
  self._ended = vim.loop.hrtime()
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
  if not self:is_done() then
    return (vim.loop.hrtime() - self._started) / 1e6
  end
  return (self._ended - self._started) / 1e6
end

---@param fn fun()
function Task:schedule(fn)
  local done = false
  table.insert(self._running, function()
    return not done
  end)
  vim.schedule(function()
    ---@type boolean, string|any
    local ok, err = pcall(fn)
    if not ok then
      self.error = err or "failed"
    end
    done = true
    self:_check()
  end)
end

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

  ---@param output string
  function opts.on_exit(ok, output)
    self.output = self.output .. output
    if not ok then
      self.error = self.error and (self.error .. "\n" .. output) or output
    end
    if on_exit then
      pcall(on_exit, ok, output)
    end
    self:_check()
  end
  local proc = Process.spawn(cmd, opts)
  table.insert(self._running, function()
    return proc and not proc:is_closing()
  end)
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
