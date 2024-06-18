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
  local rockspec = {}
  local ret, err = loadfile(rockspec_file, "t", rockspec)
  if not ret then
    error(err)
  end
  ret()
  return rockspec
      and rockspec.package
      and {
        source = "rockspec",
        file = rockspec_file,
        spec = {
          dir = plugin.dir,
          url = plugin.url,
          rocks = vim.tbl_filter(function(dep)
            local name = dep:gsub("%s.*", "")
            return not vim.tbl_contains(M.skip, name)
          end, rockspec.dependencies),
        },
      }
    or nil
end

return M
