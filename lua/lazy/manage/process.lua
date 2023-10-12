local Config = require("lazy.core.config")

local M = {}

---@type table<uv_process_t, true>
M.running = {}

M.signals = {
  "HUP",
  "INT",
  "QUIT",
  "ILL",
  "TRAP",
  "ABRT",
  "BUS",
  "FPE",
  "KILL",
  "USR1",
  "SEGV",
  "USR2",
  "PIPE",
  "ALRM",
  "TERM",
  "CHLD",
  "CONT",
  "STOP",
  "TSTP",
  "TTIN",
  "TTOU",
  "URG",
  "XCPU",
  "XFSZ",
  "VTALRM",
  "PROF",
  "WINCH",
  "IO",
  "PWR",
  "EMT",
  "SYS",
  "INFO",
}

---@diagnostic disable-next-line: no-unknown
local uv = vim.loop

---@class ProcessOpts
---@field args string[]
---@field cwd? string
---@field on_line? fun(string)
---@field on_exit? fun(ok:boolean, output:string)
---@field timeout? number
---@field env? table<string,string>

---@param opts? ProcessOpts
---@param cmd string
function M.spawn(cmd, opts)
  opts = opts or {}
  opts.timeout = opts.timeout or (Config.options.git and Config.options.git.timeout * 1000)

  ---@type table<string, string>
  local env = vim.tbl_extend("force", {
    GIT_SSH_COMMAND = "ssh -oBatchMode=yes",
  }, uv.os_environ(), opts.env or {})
  env.GIT_DIR = nil
  env.GIT_WORK_TREE = nil
  env.GIT_TERMINAL_PROMPT = "0"
  env.GIT_INDEX_FILE = nil

  ---@type string[]
  local env_flat = {}
  for k, v in pairs(env) do
    env_flat[#env_flat + 1] = k .. "=" .. v
  end

  local stdout = assert(uv.new_pipe())
  local stderr = assert(uv.new_pipe())

  local output = ""
  ---@type uv_process_t?
  local handle = nil

  ---@type uv_timer_t
  local timeout
  local killed = false
  if opts.timeout then
    timeout = assert(uv.new_timer())
    timeout:start(opts.timeout, 0, function()
      if M.kill(handle) then
        killed = true
      end
    end)
  end

  -- make sure the cwd is valid
  if not opts.cwd and type(uv.cwd()) ~= "string" then
    opts.cwd = uv.os_homedir()
  end

  handle = uv.spawn(cmd, {
    stdio = { nil, stdout, stderr },
    args = opts.args,
    cwd = opts.cwd,
    env = env_flat,
  }, function(exit_code, signal)
    ---@cast handle uv_process_t
    M.running[handle] = nil
    if timeout then
      timeout:stop()
      timeout:close()
    end
    handle:close()
    stdout:close()
    stderr:close()
    local check = assert(uv.new_check())
    check:start(function()
      if not stdout:is_closing() or not stderr:is_closing() then
        return
      end
      check:stop()
      if opts.on_exit then
        output = output:gsub("[^\r\n]+\r", "")
        if killed then
          output = output .. "\n" .. "Process was killed because it reached the timeout"
        elseif signal ~= 0 then
          output = output .. "\n" .. "Process was killed with SIG" .. M.signals[signal]
        end

        vim.schedule(function()
          opts.on_exit(exit_code == 0 and signal == 0, output)
        end)
      end
    end)
  end)

  if not handle then
    if opts.on_exit then
      opts.on_exit(false, "Failed to spawn process " .. cmd .. " " .. vim.inspect(opts))
    end
    return
  end
  M.running[handle] = true

  ---@param data? string
  local function on_output(err, data)
    assert(not err, err)

    if data then
      output = output .. data:gsub("\r\n", "\n")
      local lines = vim.split(vim.trim(output:gsub("\r$", "")):gsub("[^\n\r]+\r", ""), "\n")

      if opts.on_line then
        vim.schedule(function()
          opts.on_line(lines[#lines])
        end)
      end
    end
  end

  uv.read_start(stdout, on_output)
  uv.read_start(stderr, on_output)

  return handle
end

function M.kill(handle)
  if handle and not handle:is_closing() then
    M.running[handle] = nil
    uv.process_kill(handle, "sigint")
    return true
  end
end

function M.abort()
  for handle in pairs(M.running) do
    M.kill(handle)
  end
end

---@param cmd string[]
---@param opts? {cwd:string, env:table}
function M.exec(cmd, opts)
  opts = opts or {}
  ---@type string[]
  local lines
  local job = vim.fn.jobstart(cmd, {
    cwd = opts.cwd,
    pty = false,
    env = opts.env,
    stdout_buffered = true,
    on_stdout = function(_, _lines)
      lines = _lines
    end,
  })
  vim.fn.jobwait({ job })
  return lines
end

return M
