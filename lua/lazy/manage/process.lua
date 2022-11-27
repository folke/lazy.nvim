local M = {}

---@alias ProcessOpts {args: string[], cwd?: string, on_line?:fun(string), on_exit?: fun(ok:boolean, output:string)}

function M.spawn(cmd, opts)
  opts = opts or {}
  local env = {
    "GIT_TERMINAL_PROMPT=0",
    "GIT_SSH_COMMAND=ssh -oBatchMode=yes",
  }

  for key, value in
    pairs(vim.loop.os_environ() --[[@as string[] ]])
  do
    table.insert(env, key .. "=" .. value)
  end

  local stdout = vim.loop.new_pipe()
  local stderr = vim.loop.new_pipe()

  local output = ""
  ---@type vim.loop.Process
  local handle = nil

  handle = vim.loop.spawn(cmd, {
    stdio = { nil, stdout, stderr },
    args = opts.args,
    cwd = opts.cwd,
    env = env,
  }, function(exit_code)
    handle:close()
    stdout:close()
    stderr:close()
    local check = vim.loop.new_check()
    check:start(function()
      if not stdout:is_closing() or not stderr:is_closing() then
        return
      end
      check:stop()
      if opts.on_exit then
        output = output:gsub("[^\r\n]+\r", "")

        vim.schedule(function()
          opts.on_exit(exit_code == 0, output)
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

  vim.loop.read_start(stdout, on_output)
  vim.loop.read_start(stderr, on_output)

  return handle
end

-- FIXME: can be removed?
function M.all_done(slot0)
  for slot4, slot5 in ipairs(slot0) do
    if slot5 and not slot5:is_closing() then
      return false
    end
  end

  return true
end

return M
