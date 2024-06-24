local Config = require("lazy.core.config")
local Util = require("lazy.util")

local M = {}
M.VERSION = 8
M.dirty = false

---@class LazyPkg
---@field name string
---@field dir string
---@field source "lazy" | "packspec" | "rockspec"
---@field file string
---@field spec LazyPluginSpec

---@class LazyPkgSpec
---@field file string
---@field spec? LazySpec
---@field code? string

---@class LazyPkgSource
---@field name string
---@field get fun(plugin:LazyPlugin):LazyPkgSpec?

---@class LazyPkgCache
---@field pkgs LazyPkg[]
---@field version number

---@type LazyPkg[]?
M.cache = nil

function M.update()
  ---@type LazyPkgSource[]
  local sources = {}
  for _, s in ipairs(Config.options.pkg.sources) do
    sources[#sources + 1] = {
      name = s,
      get = require("lazy.pkg." .. s).get,
    }
  end

  ---@type LazyPkgCache
  local ret = {
    version = M.VERSION,
    pkgs = {},
  }
  for _, plugin in pairs(Config.plugins) do
    if plugin._.installed then
      for _, source in ipairs(sources) do
        local spec = source.get(plugin)
        if spec then
          ---@type LazyPkg
          local pkg = {
            name = plugin.name,
            dir = plugin.dir,
            source = source.name,
            file = spec.file,
            spec = spec.spec or {},
          }
          if type(spec.code) == "string" then
            pkg.spec = { _raw = spec.code }
          end
          table.insert(ret.pkgs, pkg)
          break
        end
      end
    end
  end
  table.sort(ret.pkgs, function(a, b)
    return a.name < b.name
  end)
  local code = "return " .. Util.dump(ret)
  vim.fn.mkdir(vim.fn.fnamemodify(Config.options.pkg.cache, ":h"), "p")
  Util.write_file(Config.options.pkg.cache, code)
  M.dirty = false
  M.cache = nil
end

local function _load()
  Util.track("pkg")
  M.cache = nil
  if vim.uv.fs_stat(Config.options.pkg.cache) then
    Util.try(function()
      local chunk, err = loadfile(Config.options.pkg.cache)
      if not chunk then
        error(err)
      end
      ---@type LazyPkgCache?
      local ret = chunk()
      if ret and ret.version == M.VERSION then
        M.cache = {}
        for _, pkg in ipairs(ret.pkgs) do
          if type(pkg.spec) == "function" then
            pkg.spec = pkg.spec()
          end
          -- wrap in the scope of the plugin
          pkg.spec = { pkg.name, specs = pkg.spec }
        end
        M.cache = ret.pkgs
      end
    end, "Error loading pkg:")
  end
  if rawget(M, "cache") then
    M.dirty = false
  else
    M.cache = {}
    M.dirty = true
  end
  Util.track()
end

---@param dir string
---@return LazyPkg?
---@overload fun():LazyPkg[]
function M.get(dir)
  if dir then
    for _, pkg in ipairs(M.cache) do
      if pkg.dir == dir then
        return pkg
      end
    end
    return
  end
  return M.cache
end

return setmetatable(M, {
  __index = function(_, key)
    if key == "cache" then
      _load()
      return M.cache
    end
  end,
})
