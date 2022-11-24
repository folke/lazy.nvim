local M = setmetatable({}, { __index = require("lazy.core.util") })

function M.file_exists(file)
  return vim.loop.fs_stat(file) ~= nil
end

function M.open(uri)
  if M.file_exists(uri) then
    return vim.cmd.view(uri)
  end
  local cmd
  if vim.fn.has("win32") == 1 then
    cmd = { "cmd.exe", "/c", "start", '""', vim.fn.shellescape(uri) }
  elseif vim.fn.has("macunix") == 1 then
    cmd = { "open", uri }
  else
    cmd = { "xdg-open", uri }
  end

  local ret = vim.fn.system(cmd)
  if vim.v.shell_error ~= 0 then
    local msg = {
      "Failed to open uri",
      ret,
      vim.inspect(cmd),
    }
    vim.notify(table.concat(msg, "\n"), vim.log.levels.ERROR)
  end
end

---@param ms number
---@param fn fun()
function M.throttle(ms, fn)
  local timer = vim.loop.new_timer()
  local running = false
  local first = true

  return function()
    if not running then
      if first then
        fn()
        first = false
      end

      timer:start(ms, 0, function()
        running = false
        vim.schedule(fn)
      end)

      running = true
    end
  end
end

function M.profile()
  local lines = { "# Profile" }

  ---@param entry LazyProfile
  local function _profile(entry, depth)
    if entry.time < 0.5 then
      -- Nothing
    end

    table.insert(
      lines,
      ("  "):rep(depth) .. "- " .. entry.name .. ": **" .. math.floor((entry.time or 0) / 1e6 * 100) / 100 .. "ms**"
    )

    for _, child in ipairs(entry) do
      _profile(child, depth + 1)
    end
  end

  for _, entry in ipairs(M._profiles[1]) do
    _profile(entry, 1)
  end

  M.markdown(lines)
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
        vim.wo[win].conceallevel = 3
        vim.wo[win].concealcursor = "n"
        vim.wo[win].spell = false

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

return M
