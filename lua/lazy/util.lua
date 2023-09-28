---@class LazyUtil: LazyUtilCore
local M = setmetatable({}, { __index = require("lazy.core.util") })

function M.file_exists(file)
  return vim.loop.fs_stat(file) ~= nil
end

---@param opts? LazyFloatOptions
---@return LazyFloat
function M.float(opts)
  return require("lazy.view.float")(opts)
end

function M.wo(win, k, v)
  if vim.api.nvim_set_option_value then
    vim.api.nvim_set_option_value(k, v, { scope = "local", win = win })
  else
    vim.wo[win][k] = v
  end
end

function M.open(uri)
  if M.file_exists(uri) then
    return M.float({ style = "", file = uri })
  end
  local Config = require("lazy.core.config")
  local cmd
  if Config.options.ui.browser then
    cmd = { Config.options.ui.browser, uri }
  elseif vim.fn.has("win32") == 1 then
    cmd = { "explorer", uri }
  elseif vim.fn.has("macunix") == 1 then
    cmd = { "open", uri }
  else
    if vim.fn.executable("xdg-open") == 1 then
      cmd = { "xdg-open", uri }
    elseif vim.fn.executable("wslview") == 1 then
      cmd = { "wslview", uri }
    else
      cmd = { "open", uri }
    end
  end

  local ret = vim.fn.jobstart(cmd, { detach = true })
  if ret <= 0 then
    local msg = {
      "Failed to open uri",
      ret,
      vim.inspect(cmd),
    }
    vim.notify(table.concat(msg, "\n"), vim.log.levels.ERROR)
  end
end

function M.read_file(file)
  local fd = assert(io.open(file, "r"))
  ---@type string
  local data = fd:read("*a")
  fd:close()
  return data
end

function M.write_file(file, contents)
  local fd = assert(io.open(file, "w+"))
  fd:write(contents)
  fd:close()
end

---@generic F: fun()
---@param ms number
---@param fn F
---@return F
function M.throttle(ms, fn)
  local timer = vim.loop.new_timer()
  local running = false
  local first = true

  return function(...)
    local args = { ... }
    local wrapped = function()
      fn(unpack(args))
    end
    if not running then
      if first then
        wrapped()
        first = false
      end

      timer:start(ms, 0, function()
        running = false
        vim.schedule(wrapped)
      end)

      running = true
    end
  end
end

---@class LazyCmdOptions: LazyFloatOptions
---@field cwd? string
---@field env? table<string,string>
---@field float? LazyFloatOptions

-- Opens a floating terminal (interactive by default)
---@param cmd? string[]|string
---@param opts? LazyCmdOptions|{interactive?:boolean}
function M.float_term(cmd, opts)
  cmd = cmd or {}
  if type(cmd) == "string" then
    cmd = { cmd }
  end
  if #cmd == 0 then
    cmd = { vim.o.shell }
  end
  opts = opts or {}
  local float = M.float(opts)
  vim.fn.termopen(cmd, vim.tbl_isempty(opts) and vim.empty_dict() or opts)
  if opts.interactive ~= false then
    vim.cmd.startinsert()
    vim.api.nvim_create_autocmd("TermClose", {
      once = true,
      buffer = float.buf,
      callback = function()
        float:close({ wipe = true })
        vim.cmd.checktime()
      end,
    })
  end
  return float
end

--- Runs the command and shows it in a floating window
---@param cmd string[]
---@param opts? LazyCmdOptions|{filetype?:string}
function M.float_cmd(cmd, opts)
  opts = opts or {}
  local float = M.float(opts)
  if opts.filetype then
    vim.bo[float.buf].filetype = opts.filetype
  end
  local Process = require("lazy.manage.process")
  local lines = Process.exec(cmd, { cwd = opts.cwd })
  vim.api.nvim_buf_set_lines(float.buf, 0, -1, false, lines)
  vim.bo[float.buf].modifiable = false
  return float
end

---@deprecated use float_term or float_cmd instead
function M.open_cmd()
  M.warn([[`require("lazy.util").open_cmd()` is deprecated. Please use `float_term` instead. Check the docs]])
end

---@return string?
function M.head(file)
  local f = io.open(file)
  if f then
    local ret = f:read()
    f:close()
    return ret
  end
end

---@return {branch: string, hash:string}?
function M.git_info(dir)
  local line = M.head(dir .. "/.git/HEAD")
  if line then
    ---@type string, string
    local ref, branch = line:match("ref: (refs/heads/(.*))")

    if ref then
      return {
        branch = branch,
        hash = M.head(dir .. "/.git/" .. ref),
      }
    end
  end
end

---@param msg string|string[]
---@param opts? table
function M.markdown(msg, opts)
  if type(msg) == "table" then
    msg = table.concat(msg, "\n") or msg
  end

  vim.notify(
    msg,
    vim.log.levels.INFO,
    vim.tbl_deep_extend("force", {
      title = "lazy.nvim",
      on_open = function(win)
        M.wo(win, "conceallevel", 3)
        M.wo(win, "concealcursor", "n")
        M.wo(win, "spell", false)

        vim.treesitter.start(vim.api.nvim_win_get_buf(win), "markdown")
      end,
    }, opts or {})
  )
end

function M._dump(value, result)
  local t = type(value)
  if t == "number" or t == "boolean" then
    table.insert(result, tostring(value))
  elseif t == "string" then
    table.insert(result, ("%q"):format(value))
  elseif t == "table" then
    table.insert(result, "{")
    local i = 1
    ---@diagnostic disable-next-line: no-unknown
    for k, v in pairs(value) do
      if k == i then
      elseif type(k) == "string" then
        table.insert(result, ("[%q]="):format(k))
      else
        table.insert(result, k .. "=")
      end
      M._dump(v, result)
      table.insert(result, ",")
      i = i + 1
    end
    table.insert(result, "}")
  else
    error("Unsupported type " .. t)
  end
end

function M.dump(value)
  local result = {}
  M._dump(value, result)
  return table.concat(result, "")
end

---@generic V
---@param t table<string, V>
---@param fn fun(key:string, value:V)
---@param opts? {case_sensitive?:boolean}
function M.foreach(t, fn, opts)
  ---@type string[]
  local keys = vim.tbl_keys(t)
  pcall(table.sort, keys, function(a, b)
    if opts and opts.case_sensitive then
      return a < b
    end
    return a:lower() < b:lower()
  end)
  for _, key in ipairs(keys) do
    fn(key, t[key])
  end
end

return M
