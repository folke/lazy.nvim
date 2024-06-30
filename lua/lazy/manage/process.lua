local Async = require("lazy.async")
local Config = require("lazy.core.config")

---@diagnostic disable-next-line: no-unknown
local uv = vim.uv

---@class ProcessOpts
---@field args string[]
---@field cwd? string
---@field on_line? fun(line:string)
---@field on_exit? fun(ok:boolean, output:string)
---@field on_data? fun(data:string, is_stderr?:boolean)
---@field timeout? number
---@field env? table<string,string>

local M = {}

---@type table<uv_process_t, LazyProcess>
M.running = setmetatable({}, { __mode = "k" })

---@class LazyProcess: Async
---@field handle? uv_process_t
---@field pid? number
---@field cmd string
---@field opts ProcessOpts
---@field timeout? uv_timer_t
---@field timedout? boolean
---@field data string
---@field check? uv_check_t
---@field code? number
---@field signal? number
local Process = setmetatable({}, { __index = Async.Async })

---@param cmd string|string[]
---@param opts? ProcessOpts
function Process.new(cmd, opts)
  local self = setmetatable({}, { __index = Process })
  ---@async
  Process.init(self, function()
    self:_run()
  end)
  opts = opts or {}
  opts.args = opts.args or {}
  if type(cmd) == "table" then
    self.cmd = cmd[1]
    vim.list_extend(opts.args, vim.list_slice(cmd, 2))
  else
    self.cmd = cmd
  end
  opts.timeout = opts.timeout or (Config.options.git and Config.options.git.timeout * 1000)
  -- make sure the cwd is valid
  if not opts.cwd and type(uv.cwd()) ~= "string" then
    opts.cwd = uv.os_homedir()
  end
  opts.on_line = opts.on_line and vim.schedule_wrap(opts.on_line) or nil
  opts.on_data = opts.on_data and vim.schedule_wrap(opts.on_data) or nil
  self.data = ""
  self.opts = opts
  self.code = 1
  self.signal = 0
  return self
end

---@async
function Process:_run()
  self:guard()
  local stdout = assert(uv.new_pipe())
  local stderr = assert(uv.new_pipe())
  self.handle = uv.spawn(self.cmd, {
    stdio = { nil, stdout, stderr },
    args = self.opts.args,
    cwd = self.opts.cwd,
    env = self:env(),
  }, function(code, signal)
    self.code = code
    self.signal = signal
    if self.timeout then
      self.timeout:stop()
    end
    self.handle:close()
    stdout:close()
    stderr:close()
    self:resume()
  end)

  if self.handle then
    M.running[self.handle] = self
    stdout:read_start(function(err, data)
      self:on_data(err, data)
    end)
    stderr:read_start(function(err, data)
      self:on_data(err, data, true)
    end)
    self:suspend()
    while not (self.handle:is_closing() and stdout:is_closing() and stderr:is_closing()) do
      Async.yield()
    end
  else
    self.data = "Failed to spawn process " .. self.cmd .. " " .. vim.inspect(self.opts)
  end
  self:on_exit()
end

function Process:on_exit()
  self.data = self.data:gsub("[^\r\n]+\r", "")
  if self.timedout then
    self.data = self.data .. "\n" .. "Process was killed because it reached the timeout"
  elseif self.signal ~= 0 then
    self.data = self.data .. "\n" .. "Process was killed with SIG" .. M.signals[self.signal]:upper()
  end
  if self.opts.on_exit then
    self.opts.on_exit(self.code == 0 and self.signal == 0, self.data)
  end
end

function Process:guard()
  if self.opts.timeout then
    self.timeout = assert(uv.new_timer())
    self.timeout:start(self.opts.timeout, 0, function()
      self.timedout = true
      self:kill()
    end)
  end
end

function Process:env()
  ---@type table<string, string>
  local env = vim.tbl_extend("force", {
    GIT_SSH_COMMAND = "ssh -oBatchMode=yes",
  }, uv.os_environ(), self.opts.env or {})
  env.GIT_DIR = nil
  env.GIT_WORK_TREE = nil
  env.GIT_TERMINAL_PROMPT = "0"
  env.GIT_INDEX_FILE = nil

  ---@type string[]
  local env_flat = {}
  for k, v in pairs(env) do
    env_flat[#env_flat + 1] = k .. "=" .. v
  end
  return env_flat
end

---@param signals uv.aliases.signals|uv.aliases.signals[]|nil
function Process:kill(signals)
  if not self.handle or self.handle:is_closing() then
    return
  end
  signals = signals or { "sigterm", "sigkill" }
  signals = type(signals) == "table" and signals or { signals }
  ---@cast signals uv.aliases.signals[]
  local timer = assert(uv.new_timer())
  timer:start(0, 1000, function()
    if self.handle and not self.handle:is_closing() and #signals > 0 then
      self.handle:kill(table.remove(signals, 1))
    else
      timer:stop()
    end
  end)
end

---@param err? string
---@param data? string
---@param is_stderr? boolean
function Process:on_data(err, data, is_stderr)
  assert(not err, err)
  if not data then
    return
  end

  if self.opts.on_data then
    self.opts.on_data(data, is_stderr)
  end
  self.data = self.data .. data:gsub("\r\n", "\n")
  local lines = vim.split(vim.trim(self.data:gsub("\r$", "")):gsub("[^\n\r]+\r", ""), "\n")

  if self.opts.on_line then
    self.opts.on_line(lines[#lines])
  end
end

M.signals = {
  "hup",
  "int",
  "quit",
  "ill",
  "trap",
  "abrt",
  "bus",
  "fpe",
  "kill",
  "usr1",
  "segv",
  "usr2",
  "pipe",
  "alrm",
  "term",
  "chld",
  "cont",
  "stop",
  "tstp",
  "ttin",
  "ttou",
  "urg",
  "xcpu",
  "xfsz",
  "vtalrm",
  "prof",
  "winch",
  "io",
  "pwr",
  "emt",
  "sys",
  "info",
}

---@param cmd string|string[]
---@param opts? ProcessOpts
function M.spawn(cmd, opts)
  return Process.new(cmd, opts)
end

function M.abort()
  for _, proc in pairs(M.running) do
    proc:kill()
  end
end

---@async
---@param cmd string|string[]
---@param opts? ProcessOpts
function M.exec(cmd, opts)
  opts = opts or {}
  local proc = M.spawn(cmd, opts)
  proc:wait()
  return vim.split(proc.data, "\n"), proc.code
end

return M
