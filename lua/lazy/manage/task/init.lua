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

---@class LazyTask: Async
---@field plugin LazyPlugin
---@field name string
---@field private _log LazyMsg[]
---@field private _started number
---@field private _ended? number
---@field private _opts TaskOptions
---@field private _level number
local Task = setmetatable({}, { __index = Async.Async })

---@class TaskOptions: {[string]:any}
---@field on_done? fun(task:LazyTask)

---@param plugin LazyPlugin
---@param name string
---@param opts? TaskOptions
---@param task LazyTaskFn
function Task.new(plugin, name, task, opts)
  local self = setmetatable({}, { __index = Task })
  ---@async
  Task.init(self, function()
    self:_run(task)
  end)
  self:set_level()
  self._opts = opts or {}
  self._log = {}
  self.plugin = plugin
  self.name = name
  self._started = vim.uv.hrtime()
  ---@param other LazyTask
  plugin._.tasks = vim.tbl_filter(function(other)
    return other.name ~= name or other:running()
  end, plugin._.tasks or {})
  table.insert(plugin._.tasks, self)
  self:render()
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

---@async
---@param task LazyTaskFn
function Task:_run(task)
  if Config.headless() and Config.options.headless.task then
    self:log("Running task " .. self.name, vim.log.levels.INFO)
  end

  self
    :on("done", function()
      self:_done()
    end)
    :on("error", function(err)
      self:error(err)
    end)
    :on("yield", function(msg)
      self:log(msg)
    end)
  task(self, self._opts)
end

---@param msg string|string[]|LazyMsg
---@param level? number
function Task:log(msg, level)
  if type(msg) == "table" and msg.msg then
    level = msg.level or level
    msg = msg.msg
  end
  level = level or vim.log.levels.DEBUG
  self._level = math.max(self._level or 0, level or 0)
  msg = type(msg) == "table" and table.concat(msg, "\n") or msg
  ---@cast msg string
  table.insert(self._log, { msg = msg, level = level })
  self:render()
  if Config.headless() then
    self:headless()
  end
end

function Task:render()
  vim.schedule(function()
    vim.api.nvim_exec_autocmds("User", { pattern = "LazyRender", modeline = false })
  end)
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
  if Config.headless() and Config.options.headless.task then
    local ms = math.floor(self:time() + 0.5)
    self:log("Finished task " .. self.name .. " in " .. ms .. "ms", vim.log.levels.INFO)
  end
  self._ended = vim.uv.hrtime()
  if self._opts.on_done then
    self._opts.on_done(self)
  end
  self:render()
  vim.schedule(function()
    vim.api.nvim_exec_autocmds("User", {
      pattern = "LazyPlugin" .. self.name:sub(1, 1):upper() .. self.name:sub(2),
      data = { plugin = self.plugin.name },
    })
  end)
end

function Task:time()
  return ((self._ended or vim.uv.hrtime()) - self._started) / 1e6
end

---@async
---@param cmd string
---@param opts? ProcessOpts
function Task:spawn(cmd, opts)
  opts = opts or {}
  local on_line = opts.on_line

  local headless = Config.headless() and Config.options.headless.process

  function opts.on_line(line)
    if not headless then
      return self:log(line, vim.log.levels.TRACE)
    end
    if on_line then
      pcall(on_line, line)
    end
  end

  if headless then
    opts.on_data = function(data)
      -- prefix with plugin name
      io.write(Terminal.prefix(data, self:prefix()))
    end
  end

  local proc = Process.spawn(cmd, opts)
  proc:wait()

  local ok = proc.code == 0 and proc.signal == 0
  if not headless then
    local msg = vim.trim(proc.data)
    if #msg > 0 then
      self:log(vim.trim(proc.data), ok and vim.log.levels.DEBUG or vim.log.levels.ERROR)
    end
  end

  if opts.on_exit then
    pcall(opts.on_exit, ok, proc.data)
  end
  return ok
end

function Task:prefix()
  local plugin = "[" .. self.plugin.name .. "] "
  local task = string.rep(" ", 20 - #(self.name .. self.plugin.name)) .. self.name

  return colors and Terminal.magenta(plugin) .. Terminal.cyan(task) .. Terminal.bright_black(" | ")
    or plugin .. " " .. task .. " | "
end

return Task
