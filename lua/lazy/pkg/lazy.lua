local Util = require("lazy.util")

local M = {}

M.lazy_file = "lazy.lua"

---@param plugin LazyPlugin
---@return LazyPkg?
function M.get(plugin)
  local file = Util.norm(plugin.dir .. "/" .. M.lazy_file)
  if Util.file_exists(file) then
    ---@type fun(): LazySpec
    local chunk = Util.try(function()
      local ret, err = loadfile(file)
      return err and error(err) or ret
    end, "`" .. M.lazy_file .. "` for **" .. plugin.name .. "** has errors:")
    if not chunk then
      Util.error("Invalid `" .. M.lazy_file .. "` for **" .. plugin.name .. "**")
    end
    return {
      source = "lazy",
      file = M.lazy_file,
      chunk = chunk,
    }
  end
end

return M
