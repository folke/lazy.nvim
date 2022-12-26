local Cache = require("lazy.core.cache")
local Config = require("lazy.core.config")
local Util = require("lazy.util")
local Plugin = require("lazy.core.plugin")
local Loader = require("lazy.core.loader")

local M = {}

---@type table<string, CacheHash>
M.files = {}

---@type vim.loop.Timer
M.timer = nil
M.root = nil

function M.enable()
  if M.timer then
    M.timer:stop()
  end
  if type(Config.spec) == "string" then
    M.timer = vim.loop.new_timer()
    M.root = vim.fn.stdpath("config") .. "/lua"
    M.check(true)
    M.timer:start(2000, 2000, M.check)
  end
end

function M.disable()
  if M.timer then
    M.timer:stop()
    M.timer = nil
  end
end

function M.check(start)
  ---@type table<string,true>
  local checked = {}
  ---@type {file:string, what:string}[]
  local changes = {}

  -- spec is a module
  local function check(_, modpath)
    checked[modpath] = true
    local hash = Cache.hash(modpath)
    if hash then
      if M.files[modpath] then
        if not Cache.eq(M.files[modpath], hash) then
          M.files[modpath] = hash
          table.insert(changes, { file = modpath, what = "changed" })
        end
      else
        M.files[modpath] = hash
        table.insert(changes, { file = modpath, what = "added" })
      end
    end
  end

  Util.lsmod(Config.spec --[[@as string]], M.root, check)

  for file in pairs(M.files) do
    if not checked[file] then
      table.insert(changes, { file = file, what = "deleted" })
      M.files[file] = nil
    end
  end

  if Loader.init_done and Config.mapleader ~= vim.g.mapleader then
    vim.schedule(function()
      require("lazy.core.util").warn("You need to set `vim.g.mapleader` **BEFORE** loading lazy")
    end)
    Config.mapleader = vim.g.mapleader
  end

  if not (start or #changes == 0) then
    vim.schedule(function()
      if Config.options.change_detection.notify then
        local lines = { "# Config Change Detected. Reloading...", "" }
        for _, change in ipairs(changes) do
          table.insert(lines, "- **" .. change.what .. "**: `" .. vim.fn.fnamemodify(change.file, ":p:~:.") .. "`")
        end
        Util.warn(lines)
      end
      Plugin.load()
      vim.cmd([[do User LazyRender]])
      vim.cmd([[do User LazyReload]])
    end)
  end
end

return M
