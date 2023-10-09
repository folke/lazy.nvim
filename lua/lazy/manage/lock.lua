local Config = require("lazy.core.config")
local Git = require("lazy.manage.git")

local M = {}

---@type table<string, {commit:string, branch:string}>
M.lock = {}
M._loaded = false

function M.update()
  vim.fn.mkdir(vim.fn.fnamemodify(Config.options.lockfile, ":p:h"), "p")
  local f = assert(io.open(Config.options.lockfile, "wb"))
  f:write("{\n")
  M.lock = {}

  ---@param plugin LazyPlugin
  local plugins = vim.tbl_filter(function(plugin)
    return not plugin._.is_local and plugin._.installed
  end, Config.plugins)

  ---@param plugin LazyPlugin
  ---@type string[]
  local names = vim.tbl_map(function(plugin)
    return plugin.name
  end, plugins)
  table.sort(names)

  for n, name in ipairs(names) do
    local plugin = Config.plugins[name]
    if not plugin._.is_local and plugin._.installed then
      local info = assert(Git.info(plugin.dir))
      if not info.branch then
        info.branch = assert(Git.get_branch(plugin))
      end
      info.commit = info.commit
      -- f:write(([[  [%q] = { branch = %q, commit = %q },]]):format(name, info.branch, info.commit) .. "\n")
      f:write(([[  %q: { "branch": %q, "commit": %q }]]):format(name, info.branch, info.commit))
      if n ~= #names then
        f:write(",\n")
      end
      ---@diagnostic disable-next-line: assign-type-mismatch
      M.lock[plugin.name] = info
    end
  end
  f:write("\n}")
  f:close()
end

function M.load()
  M.lock = {}
  M._loaded = true
  local f = io.open(Config.options.lockfile, "r")
  if f then
    ---@type string
    local data = f:read("*a")
    local ok, lock = pcall(vim.json.decode, data)
    if ok then
      M.lock = lock
    end
    f:close()
  end
end

---@param plugin LazyPlugin
---@return {commit:string, branch:string}
function M.get(plugin)
  if not M._loaded then
    M.load()
  end
  return M.lock[plugin.name]
end

return M
