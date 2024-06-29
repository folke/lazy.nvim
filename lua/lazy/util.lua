---@class LazyUtil: LazyUtilCore
local M = setmetatable({}, { __index = require("lazy.core.util") })

function M.file_exists(file)
  return vim.uv.fs_stat(file) ~= nil
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

---@param opts? {system?:boolean}
function M.open(uri, opts)
  opts = opts or {}
  if not opts.system and M.file_exists(uri) then
    return M.float({ style = "", file = uri })
  end
  local Config = require("lazy.core.config")
  local cmd
  if not opts.system and Config.options.ui.browser then
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
  ---@type Async
  local async
  local pending = false

  return function()
    if async and async:running() then
      pending = true
      return
    end
    ---@async
    async = require("lazy.async").new(function()
      repeat
        pending = false
        fn()
        async:sleep(ms)

      until not pending
    end)
  end
end

--- Creates a weak reference to an object.
--- Calling the returned function will return the object if it has not been garbage collected.
---@generic T: table
---@param obj T
---@return T|fun():T?
function M.weak(obj)
  local weak = { _obj = obj }
  ---@return table<any, any>
  local function get()
    local ret = rawget(weak, "_obj")
    return ret == nil and error("Object has been garbage collected", 2) or ret
  end
  local mt = {
    __mode = "v",
    __call = function(t)
      return rawget(t, "_obj")
    end,
    __index = function(_, k)
      return get()[k]
    end,
    __newindex = function(_, k, v)
      get()[k] = v
    end,
    __pairs = function()
      return pairs(get())
    end,
  }
  return setmetatable(weak, mt)
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
  local Process = require("lazy.manage.process")
  local lines, code = Process.exec(cmd, { cwd = opts.cwd })
  if code ~= 0 then
    M.error({
      "`" .. table.concat(cmd, " ") .. "`",
      "",
      "## Error",
      table.concat(lines, "\n"),
    }, { title = "Command Failed (" .. code .. ")" })
    return
  end
  local float = M.float(opts)
  if opts.filetype then
    vim.bo[float.buf].filetype = opts.filetype
  end
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
  elseif t == "table" and value._raw then
    table.insert(result, value._raw)
  elseif t == "table" then
    table.insert(result, "{")
    for _, v in ipairs(value) do
      M._dump(v, result)
      table.insert(result, ",")
    end
    ---@diagnostic disable-next-line: no-unknown
    for k, v in pairs(value) do
      if type(k) == "string" then
        if k:match("^[a-zA-Z]+$") then
          table.insert(result, ("%s="):format(k))
        else
          table.insert(result, ("[%q]="):format(k))
        end
        M._dump(v, result)
        table.insert(result, ",")
      end
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
