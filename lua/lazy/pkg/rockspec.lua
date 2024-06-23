--# selene:allow(incorrect_standard_library_use)

local Util = require("lazy.core.util")

local M = {}

M.dev_suffix = "-scm-1.rockspec"
M.skip = { "lua" }

---@class RockSpec
---@field rockspec_format string
---@field package string
---@field version string
---@field dependencies string[]

---@param plugin LazyPlugin
---@return LazyPkg?
function M.get(plugin)
  local rockspec_file ---@type string?
  Util.ls(plugin.dir, function(path, name, t)
    if t == "file" and name:sub(-#M.dev_suffix) == M.dev_suffix then
      rockspec_file = path
      return false
    end
  end)

  if not rockspec_file then
    return
  end

  ---@type RockSpec?
  ---@diagnostic disable-next-line: missing-fields
  local rockspec = {}
  local load, err = loadfile(rockspec_file, "t", rockspec)
  if not load then
    error(err)
  end
  load()

  ---@param dep string
  local rocks = vim.tbl_filter(function(dep)
    local name = dep:gsub("%s.*", "")
    return not vim.tbl_contains(M.skip, name)
  end, rockspec and rockspec.dependencies or {})

  return #rocks > 0
      and {
        source = "rockspec",
        file = vim.fn.fnamemodify(rockspec_file, ":t"),
        spec = {
          plugin.name,
          rocks = rocks,
        },
      }
    or nil
end

return M
