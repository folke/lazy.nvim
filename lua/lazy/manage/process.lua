local Config = require("lazy.core.config")

local M = {}

---@diagnostic disable-next-line: no-unknown
local uv = vim.loop

---@class ProcessOpts
---@field args string[]
---@field cwd? string
---@field on_line? fun(string)
---@field on_exit? fun(ok:boolean, output:string)
---@field timeout? number

---@param opts? ProcessOpts
function M.spawn(cmd, opts)
  opts = opts or {}
  opts.timeout = opts.timeout or (Config.options.git and Config.options.git.timeout * 1000)

  local env = {
    "GIT_TERMINAL_PROMPT=0",
    "GIT_SSH_COMMAND=ssh -oBatchMode=yes",
  }

  for key, value in
    pairs(uv.os_environ() --[[@as string[] ]])
  do
    table.insert(env, key .. "=" .. value)
  end

  local stdout = uv.new_pipe()
  local stderr = uv.new_pipe()

  local output = ""
  ---@type vim.loop.Process
  local handle = nil

  local timeout
  local killed = false
  if opts.timeout then
    timeout = uv.new_timer()
    timeout:start(opts.timeout, 0, function()
      if handle and not handle:is_closing() then
        killed = true
        uv.process_kill(handle, "sigint")
      end
    end)
  end

  handle = uv.spawn(cmd, {
    stdio = { nil, stdout, stderr },
    args = opts.args,
    cwd = opts.cwd,
    env = env,
  }, function(exit_code, signal)
    if timeout then
      timeout:stop()
      timeout:close()
    end
    handle:close()
    stdout:close()
    stderr:close()
    local check = uv.new_check()
    check:start(function()
      if not stdout:is_closing() or not stderr:is_closing() then
        return
      end
      check:stop()
      if opts.on_exit then
        output = output:gsub("[^\r\n]+\r", "")
        if killed then
          output = output .. "\n" .. "Process was killed because it reached the timeout"
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
