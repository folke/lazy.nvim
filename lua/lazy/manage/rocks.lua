--# selene:allow(incorrect_standard_library_use)

local Config = require("lazy.core.config")
local Util = require("lazy.core.util")

---@class LazyRock
---@field plugin string
---@field name string
---@field spec string
---@field installed boolean

local M = {}
---@type LazyRock[]
M.rocks = {}

---@param ... string
---@return string[]
function M.args(...)
  local ret = { "--tree", Config.rocks.tree, "--lua-version", "5.1" }
  vim.list_extend(ret, { ... })
  return ret
end

function M.parse(rockspec_file)
  local rockspec = {}
  local ret, err = loadfile(rockspec_file, "t", rockspec)
  if not ret then
    error(err)
  end
  ret()
  return rockspec
end

-- dd(M.parse("/home/folke/.local/share/nvim/lazy/neorg/neorg-scm-1.rockspec"))

---@param plugin LazyPlugin
function M.get_rockspec(plugin)
  assert(plugin.rocks and #plugin.rocks > 0, plugin.name .. " has no rocks")
  local rockspec_file = Config.rocks.specs .. "/lazy-" .. plugin.name .. "-0.0-0.rockspec"
  require("lazy.util").write_file(
    rockspec_file,
    ([[
rockspec_format = "3.0"
package = "lazy-%s"
version = "0.0-0"
source = { url = "%s" }
dependencies = %s
build = { type = "builtin" }
]]):format(plugin.name, plugin.url, vim.inspect(plugin.rocks))
  )
  return rockspec_file
end

function M.update_state()
  local root = Config.rocks.tree .. "/lib/luarocks/rocks-5.1"
  ---@type table<string,string>
  local installed = {}
  Util.ls(root, function(_, name, type)
    if type == "directory" then
      installed[name] = name
    end
  end)

  ---@type LazyRock[]
  local rocks = {}
  M.rocks = rocks

  for _, plugin in pairs(Config.plugins) do
    if plugin.rocks then
      plugin._.rocks = {}
      plugin._.rocks_installed = true
      for _, spec in ipairs(plugin.rocks) do
        spec = vim.trim(spec)
        local name = spec:gsub("%s.*", "")
        local rock = {
          plugin = plugin.name,
          name = name,
          spec = spec,
          installed = installed[name] ~= nil,
        }
        plugin._.rocks_installed = plugin._.rocks_installed and rock.installed
        table.insert(plugin._.rocks, rock)
        table.insert(rocks, rock)
      end
    end
  end
end

return M
