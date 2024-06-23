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
      return
    end
    return {
      source = "lazy",
      file = M.lazy_file,
      code = "function()\n" .. Util.read_file(file) .. "\nend",
    }
  end
end

return M
