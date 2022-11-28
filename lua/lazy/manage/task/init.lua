local Process = require("lazy.manage.process")

---@class LazyTaskDef
---@field skip? fun(plugin:LazyPlugin, opts:RunnerOpts):any?
---@field run fun(task:LazyTask)

---@alias LazyTaskState fun():boolean?

---@class LazyTask
---@field plugin LazyPlugin
---@field type TaskType
---@field output string
---@field status string
---@field error? string
---@field private _task fun(task:LazyTask)
---@field private _running LazyPluginState[]
---@field private _started boolean
---@field private _opts TaskOptions
local Task = {}

---@alias TaskType "update"|"install"|"run"|"clean"|"log"|"docs"

---@class TaskOptions
---@field on_done? fun(task:LazyTask)

---@param plugin LazyPlugin
---@param type TaskType
---@param opts? TaskOptions
---@param task fun(task:LazyTask)
function Task.new(plugin, type, task, opts)
  local self = setmetatable({}, {
    __index = Task,
  })
  self._opts = opts or {}
  self._running = {}
  self._task = task
  self._started = false
  self.plugin = plugin
  self.type = type
  self.output = ""
  self.status = ""
  plugin._.tasks = plugin._.tasks or {}
  table.insert(plugin._.tasks, self)
  return self
end

function Task:has_started()
  return self._started
end

function Task:is_done()
  return self:has_started() and not self:is_running()
end

function Task:is_running()
  for _, state in ipairs(self._running) do
    if state() then
      return true
    end
  end
  return false
end

function Task:start()
  self._started = true
  ---@type boolean, string|any
  local ok, err = pcall(self._task, self)
  if not ok then
    self.error = err or "failed"
  end
  self:_check()
end

---@private
function Task:_check()
  if self:is_running() then
    return
  end
  if self._opts.on_done then
    self._opts.on_done(self)
  end
  vim.cmd("do User LazyRender")
  vim.api.nvim_exec_autocmds("User", {
    pattern = "LazyPlugin" .. self.type:sub(1, 1):upper() .. self.type:sub(2),
    data = { plugin = self.plugin.name },
  })
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
    vim.cmd("do User LazyRender")
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
