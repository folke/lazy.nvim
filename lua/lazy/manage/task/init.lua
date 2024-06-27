local Async = require("lazy.async")
local Config = require("lazy.core.config")
local Process = require("lazy.manage.process")
local Terminal = require("lazy.terminal")

local colors = Config.options.headless.colors

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
  self:set_level()
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
  local msg = ret and vim.trim(ret.msg) or ""
  return msg ~= "" and msg or nil
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

---@param level? number
function Task:set_level(level)
  self._level = level or vim.log.levels.TRACE
end

---@private
---@param task LazyTaskFn
function Task:_start(task)
  assert(not self:has_started(), "task already started")
  assert(not self:has_ended(), "task already done")

  if Config.headless() and Config.options.headless.task then
    self:log("Running task " .. self.name, vim.log.levels.INFO)
  end

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
  if Config.headless() then
    self:headless()
  end
end

function Task:headless()
  if not Config.options.headless.log then
    return
  end
  local msg = self._log[#self._log]
  if not msg or msg.level == vim.log.levels.TRACE then
    return
  end
  local map = {
    [vim.log.levels.ERROR] = Terminal.red,
    [vim.log.levels.WARN] = Terminal.yellow,
    [vim.log.levels.INFO] = Terminal.blue,
  }
  local color = Config.options.headless.colors and map[msg.level]
  io.write(Terminal.prefix(color and color(msg.msg) or msg.msg, self:prefix()))
  io.write("\n")
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

  if Config.headless() and Config.options.headless.task then
    local ms = math.floor(self:time() + 0.5)
    self:log("Finished task " .. self.name .. " in " .. ms .. "ms", vim.log.levels.INFO)
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

  local headless = Config.headless() and Config.options.headless.process

  function opts.on_line(line)
    if not headless then
      return self:log(line, vim.log.levels.TRACE)
    end
    if on_line then
      pcall(on_line, line)
    end
  end

  local running = true
  local ret = true
  ---@param output string
  function opts.on_exit(ok, output)
    if not headless then
      self:log(vim.trim(output), ok and vim.log.levels.DEBUG or vim.log.levels.ERROR)
    end
    if on_exit then
      pcall(on_exit, ok, output)
    end
    ret = ok
    running = false
  end

  if headless then
    opts.on_data = function(data)
      -- prefix with plugin name
      local prefix = self:prefix()
      io.write(Terminal.prefix(data, prefix))
    end
  end
  Process.spawn(cmd, opts)
  while running do
    coroutine.yield()
  end
  return ret
end

function Task:prefix()
  local plugin = "[" .. self.plugin.name .. "] "
  local task = string.rep(" ", 20 - #(self.name .. self.plugin.name)) .. self.name

  return colors and Terminal.magenta(plugin) .. Terminal.cyan(task) .. Terminal.bright_black(" | ")
    or plugin .. " " .. task .. " | "
end

function Task:wait()
  while self:is_running() do
    vim.wait(10)
  end
end

return Task
