local Util = require("lazy.util")

---@class PackSpec
---@field dependencies? table<string, string>
---@field lazy? LazyPluginSpec
---
local M = {}

M.pkg_file = "pkg.json"

---@param plugin LazyPlugin
---@return LazyPkg?
function M.get(plugin)
  local file = Util.norm(plugin.dir .. "/" .. M.pkg_file)
  if not Util.file_exists(file) then
    return
  end
  ---@type PackSpec
  local pkg = Util.try(function()
    return vim.json.decode(Util.read_file(file))
  end, "`" .. M.pkg_file .. "` for **" .. plugin.name .. "** has errors:")

  if not pkg then
    return
  end

  ---@type LazySpec
  local ret = {}
  if pkg.dependencies then
    for url, version in pairs(pkg.dependencies) do
      -- HACK: Add `.git` to github urls
      if url:find("github") and not url:match("%.git$") then
        url = url .. ".git"
      end
      ret[#ret + 1] = { url = url, version = version }
    end
  end
  local p = pkg.lazy
  if p then
    p.url = p.url or plugin.url
    p.dir = p.dir or plugin.dir
    ret[#ret + 1] = p
  end
  if pkg.lazy then
    ret[#ret + 1] = pkg.lazy
  end
  return {
    source = "lazy",
    file = M.pkg_file,
    spec = ret,
  }
end

return M
