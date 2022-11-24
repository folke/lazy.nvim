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
---@alias DirEntry {name: string, path: string, type: FileType}[]
---@param path string
---@param fn fun(path: string, name:string, type:FileType)
function M.scandir(path, fn)
  local dir = vim.loop.fs_opendir(path, nil, 100)
  if dir then
    local entries = vim.loop.fs_readdir(dir) --[[@as DirEntry[]]
    while entries do
      for _, entry in ipairs(entries) do
        entry.path = path .. "/" .. entry.name
        fn(path .. "/" .. entry.name, entry.name, entry.type)
      end
      entries = vim.loop.fs_readdir(dir)
    end
    vim.loop.fs_closedir(dir)
  end
end
---@param path string
---@param fn fun(path: string, name:string, type:FileType)
function M.ls(path, fn)
  local handle = vim.loop.fs_scandir(path)
  while handle do
    local name, t = vim.loop.fs_scandir_next(handle)
    if not name then
      break
    end
    fn(path .. "/" .. name, name, t)
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

---@param root string
---@param fn fun(modname:string, modpath:string)
function M.lsmod(root, fn)
  M.ls(root, function(path, name, type)
    if type == "file" and name:sub(-4) == ".lua" then
      fn(name:sub(1, -5), path)
    elseif type == "directory" and vim.loop.fs_stat(path .. "/init.lua") then
      fn(name, path .. "/init.lua")
    end
  end)
end

function M.error(msg)
  vim.notify(msg, vim.log.levels.ERROR, {
    title = "lazy.nvim",
  })
end

function M.info(msg)
  vim.notify(msg, vim.log.levels.INFO, {
    title = "lazy.nvim",
  })
end

return M
