local M = {}

---@alias LazyProfile {data: string|{[string]:string}, time: number, [number]:LazyProfile}

---@type LazyProfile[]
M._profiles = { { name = "lazy" } }

---@param data (string|{[string]:string})?
---@param time number?
function M.track(data, time)
  if data then
    local entry = {
      data = data,
      time = time or vim.loop.hrtime(),
    }
    table.insert(M._profiles[#M._profiles], entry)

    if not time then
      table.insert(M._profiles, entry)
    end
    return entry
  else
    ---@type LazyProfile
    local entry = table.remove(M._profiles)
    entry.time = vim.loop.hrtime() - entry.time
    return entry
  end
end

function M.norm(path)
  if path:sub(1, 1) == "~" then
    local home = vim.loop.os_homedir()
    if home:sub(-1) == "\\" or home:sub(-1) == "/" then
      home = home:sub(1, -2)
    end
    path = home .. path:sub(2)
  end
  return path:gsub("\\", "/")
end

function M.try(fn, msg)
  -- error handler
  local error_handler = function(err)
    local Config = require("lazy.core.config")
    local trace = {}
    local level = 1
    while true do
      local info = debug.getinfo(level, "Sln")
      if not info then
        break
      end
      if info.what ~= "C" and not info.source:find("lazy.nvim") then
        local source = info.source:sub(2)
        if source:find(Config.options.root, 1, true) == 1 then
          source = source:sub(#Config.options.root + 1)
        end
        source = vim.fn.fnamemodify(source, ":p:~:.")
        local line = "  - " .. source .. ":" .. info.currentline
        if info.name then
          line = line .. " _in_ **" .. info.name .. "**"
        end
        table.insert(trace, line)
      end
      level = level + 1
    end
    msg = msg .. "\n\n" .. err
    if #trace > 0 then
      msg = msg .. "\n\n# stacktrace:\n" .. table.concat(trace, "\n")
    end
    vim.schedule(function()
      M.error(msg)
    end)
    return err
  end

  ---@type boolean, any
  local ok, result = xpcall(fn, error_handler)
  return ok and result or nil
end

function M.get_source()
  local f = 2
  while true do
    local info = debug.getinfo(f, "S")
    if not info then
      break
    end
    if info.what ~= "C" and not info.source:find("lazy.nvim", 1, true) then
      return info.source:sub(2)
    end
    f = f + 1
  end
end

-- Fast implementation to check if a table is a list
---@param t table
function M.is_list(t)
  local i = 0
  ---@diagnostic disable-next-line: no-unknown
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then
      return false
    end
  end
  return true
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

---@alias FileType "file"|"directory"|"link"
---@param path string
---@param fn fun(path: string, name:string, type:FileType):boolean?
function M.ls(path, fn)
  local handle = vim.loop.fs_scandir(path)
  while handle do
    local name, t = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end
    if fn(path .. "/" .. name, name, t) == false then
      break
    end
  end
end

---@param path string
---@param fn fun(path: string, name:string, type:FileType)
function M.walk(path, fn)
  M.ls(path, function(child, name, type)
    if type == "directory" then
      M.walk(child, fn)
    end
    fn(child, name, type)
  end)
end

---@param modname string
---@param root string
---@param fn fun(modname:string, modpath:string)
---@overload fun(modname:string, fn: fun(modname:string, modpath:string))
function M.lsmod(modname, root, fn)
  if type(root) == "function" then
    fn = root
    root = vim.fn.stdpath("config") .. "/lua"
  end
  root = root .. "/" .. modname:gsub("%.", "/")
  if vim.loop.fs_stat(root .. ".lua") then
    fn(modname, root .. ".lua")
  end
  M.ls(root, function(path, name, type)
    if type == "file" and name:sub(-4) == ".lua" then
      if name == "init.lua" then
        fn(modname, path)
      else
        fn(modname .. "." .. name:sub(1, -5), path)
      end
    elseif type == "directory" and vim.loop.fs_stat(path .. "/init.lua") then
      fn(modname .. "." .. name, path .. "/init.lua")
    end
  end)
end

---@param msg string|string[]
function M.notify(msg, level)
  if type(msg) == "table" then
    msg = table.concat(
      vim.tbl_filter(function(line)
        return line or false
      end, msg),
      "\n"
    )
  end
  vim.notify(msg, level, {
    on_open = function(win)
      vim.wo[win].conceallevel = 3
      vim.wo[win].concealcursor = ""
      vim.wo[win].spell = false
      local buf = vim.api.nvim_win_get_buf(win)
      vim.bo[buf].filetype = "markdown"
    end,
    title = "lazy.nvim",
  })
end

---@param msg string|string[]
function M.error(msg)
  M.notify(msg, vim.log.levels.ERROR)
end

---@param msg string|string[]
function M.info(msg)
  M.notify(msg, vim.log.levels.INFO)
end

---@param msg string|string[]
function M.warn(msg)
  M.notify(msg, vim.log.levels.WARN)
end

return M
