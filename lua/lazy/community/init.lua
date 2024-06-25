local M = {}

---@type table<string, string>
local mapping = nil

local function _load()
  if mapping then
    return
  end
  mapping = {}
  ---@type {name:string, url:string, version:string}[]
  local gen = require("lazy.community._generated")
  for _, rock in ipairs(gen) do
    mapping[rock.name] = rock.url
  end
end

---@param rock string
---@return string?
function M.get_url(rock)
  _load()
  return mapping[rock]
end

return M
