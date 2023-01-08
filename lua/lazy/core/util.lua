---@class LazyUtilCore
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

---@generic F: fun()
---@param data (string|{[string]:string})?
---@param fn F
---@return F
function M.trackfn(data, fn)
  return function(...)
    M.track(data)
    local ok, ret = pcall(fn, ...)
    M.track()
    if not ok then
      error(ret)
    end
    return ret
  end
end

---@param name string
---@return string
function M.normname(name)
  local ret = name:lower():gsub("^n?vim%-", ""):gsub("%.n?vim$", ""):gsub("%.lua", ""):gsub("[^a-z]+", "")
  return ret
end

---@return string
function M.norm(path)
  if path:sub(1, 1) == "~" then
    local home = vim.loop.os_homedir()
    if home:sub(-1) == "\\" or home:sub(-1) == "/" then
      home = home:sub(1, -2)
    end
    path = home .. path:sub(2)
  end
  path = path:gsub("\\", "/"):gsub("/+", "/")
  return path:sub(-1) == "/" and path:sub(1, -2) or path
end

---@param opts? string|{msg:string, on_error:fun(msg)}
function M.try(fn, opts)
  opts = type(opts) == "string" and { msg = opts } or opts or {}
  local msg = opts.msg
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
    msg = (msg and (msg .. "\n\n") or "") .. err
    if #trace > 0 then
      msg = msg .. "\n\n# stacktrace:\n" .. table.concat(trace, "\n")
    end
    if opts.on_error then
      opts.on_error(msg)
    else
      vim.schedule(function()
        M.error(msg)
      end)
    end
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
      vim.g.did_very_lazy = true
      vim.cmd("do User VeryLazy")
    end, 50)
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
    -- HACK: assume type is a file if no type returned
    -- see https://github.com/folke/lazy.nvim/issues/306
    t = t or "file"
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
---@param fn fun(modname:string, modpath:string)
function M.lsmod(modname, fn)
  local Cache = require("lazy.core.cache")
  local root = Cache.find_root(modname)
  if not root then
    return
  end

  if vim.loop.fs_stat(root .. ".lua") then
    fn(modname, root .. ".lua")
  end

  M.ls(root, function(path, name, type)
    if name == "init.lua" then
      fn(modname, path)
    elseif (type == "file" or type == "link") and name:sub(-4) == ".lua" then
      fn(modname .. "." .. name:sub(1, -5), path)
    elseif type == "directory" and vim.loop.fs_stat(path .. "/init.lua") then
      fn(modname .. "." .. name, path .. "/init.lua")
    end
  end)
end

---@param msg string|string[]
---@param opts? {lang:string, title:string}
function M.notify(msg, level, opts)
  if vim.in_fast_event() then
    vim.schedule(function()
      M.notify(msg, level, opts)
    end)
    return
  end

  opts = opts or {}
  if type(msg) == "table" then
    msg = table.concat(
      vim.tbl_filter(function(line)
        return line or false
      end, msg),
      "\n"
    )
  end
  local lang = opts.lang or "markdown"
  vim.notify(msg, level, {
    on_open = function(win)
      pcall(require, "nvim-treesitter")
      vim.wo[win].conceallevel = 3
      vim.wo[win].concealcursor = ""
      vim.wo[win].spell = false
      local buf = vim.api.nvim_win_get_buf(win)
      if not pcall(vim.treesitter.start, buf, lang) then
        vim.bo[buf].filetype = lang
        vim.bo[buf].syntax = lang
      end
    end,
    title = "lazy.nvim" .. (opts.title and ": " .. opts.title or ""),
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

---@param msg string|table
---@param level? number
---@param opts? {lang:string, title:string}
function M.debug(msg, level, opts)
  if not require("lazy.core.config").options.debug then
    return
  end
  opts = opts or {}
  if type(msg) == "string" then
    M.notify(msg, level, opts)
  else
    opts.lang = "lua"
    M.notify(vim.inspect(msg), level, opts)
  end
end

local function can_merge(v)
  return type(v) == "table" and (vim.tbl_isempty(v) or not M.is_list(v))
end

--- Merges the values similar to vim.tbl_deep_extend with the **force** behavior,
--- but the values can be any type, in which case they override the values on the left.
--- Values will me merged in-place in the first left-most table. If you want the result to be in
--- a new table, then simply pass an empty table as the first argument `vim.merge({}, ...)`
--- Supports clearing values by setting a key to `vim.NIL`
function M.merge(...)
  local values = { ... }
  local ret = values[1]
  for i = 2, #values, 1 do
    local value = values[i]
    if can_merge(ret) and can_merge(value) then
      for k, v in pairs(value) do
        ret[k] = M.merge(ret[k], v)
      end
    elseif value == vim.NIL then
      ret = nil
    else
      ret = value
    end
  end
  return ret
end

return M
