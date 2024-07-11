local Config = require("lazy.core.config")
local Git = require("lazy.manage.git")

local M = {}

---@alias LazyLockfile table<string, {commit:string, branch:string}>
---@type LazyLockfile
M.lock = {}
M._loaded = false

function M.update()
  M.load()
  vim.fn.mkdir(vim.fn.fnamemodify(Config.options.lockfile, ":p:h"), "p")
  local f = assert(io.open(Config.options.lockfile, "wb"))
  f:write("{\n")

  -- keep disabled and cond plugins
  for name in pairs(M.lock) do
    if not (Config.spec.disabled[name] or Config.spec.ignore_installed[name]) then
      M.lock[name] = nil
    end
  end

  for _, plugin in pairs(Config.plugins) do
    if not plugin._.is_local and plugin._.installed then
      local info = assert(Git.info(plugin.dir))
      M.lock[plugin.name] = {
        branch = info.branch or assert(Git.get_branch(plugin)),
        commit = assert(info.commit, "commit is nil"),
      }
    end
  end

  ---@type string[]
  local names = vim.tbl_keys(M.lock)
  table.sort(names)

  for n, name in ipairs(names) do
    local info = M.lock[name]
    f:write(([[  %q: { "branch": %q, "commit": %q }]]):format(name, info.branch, info.commit))
    if n ~= #names then
      f:write(",\n")
    end
  end
  f:write("\n}\n")
  f:close()
end

function M.load()
  if M._loaded then
    return
  end
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
  M.load()
  return M.lock[plugin.name]
end

return M
