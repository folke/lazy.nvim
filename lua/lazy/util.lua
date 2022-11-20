local M = {}

---@alias LazyProfile {name: string, time: number, [number]:LazyProfile}

---@type LazyProfile[]
M._profiles = { { name = "lazy" } }

---@param name string?
---@param time number?
function M.track(name, time)
  if name then
    local entry = {
      name = name,
      time = time or M.time(),
    }
    table.insert(M._profiles[#M._profiles], entry)

    if not time then
      table.insert(M._profiles, entry)
    end
  else
    local entry = table.remove(M._profiles)
    entry.time = M.time() - entry.time
  end
end

function M.time()
  return vim.loop.hrtime() / 1000000
end

function M.file_exists(file)
  return vim.loop.fs_stat(file) ~= nil
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

function M.very_lazy()
  local function _load()
    vim.defer_fn(function()
      vim.cmd("do User VeryLazy")
    end, 100)
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyDone",
    once = true,
    callback = function()
      if vim.v.vim_did_enter == 1 then
        _load()
      else
        vim.api.nvim_create_autocmd("VimEnter", {
          once = true,
          callback = function()
            _load()
          end,
        })
      end
    end,
  })
end

---@param path string
function M.scandir(path)
  ---@type {name: string, path: string, type: "file"|"directory"|"link"}[]
  local ret = {}

  local dir = vim.loop.fs_opendir(path, nil, 100)

  if dir then
    ---@type {name: string, path: string, type: "file"|"directory"|"link"}[]
    local entries = vim.loop.fs_readdir(dir)
    while entries do
      for _, entry in ipairs(entries) do
        entry.path = path .. "/" .. entry.name
        table.insert(ret, entry)
      end
      entries = vim.loop.fs_readdir(dir)
    end
    vim.loop.fs_closedir(dir)
  end

  return ret
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
      ("  "):rep(depth) .. "- " .. entry.name .. ": **" .. math.floor((entry.time or 0) * 100) / 100 .. "ms**"
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
    f:close()
    return f:read()
  end
end

---@return {branch: string, hash:string}?
function M.git_info(dir)
  if M.head(dir .. "/.git/HEAD") then
    ---@type string, string
    local ref, branch = slot1:match("ref: (refs/heads/(.*))")

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

function M.error(msg)
  vim.notify(msg, vim.log.levels.ERROR, {
    title = "lazy.nvim",
  })
end

return M
