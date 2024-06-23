local Config = require("lazy.core.config")
local Util = require("lazy.util")

local M = {}
M.VERSION = 7
M.dirty = false

---@alias LazyPkgSpec LazySpec | fun():LazySpec

---@class LazyPkg
---@field source string
---@field name string
---@field file string
---@field spec? LazySpec

---@class LazyPkgInput: LazyPkg
---@field spec? LazySpec|fun():LazySpec
---@field code? string

---@class LazyPkgSource
---@field get fun(plugin:LazyPlugin):LazyPkgInput?

---@type table<string, LazyPkg>?
M.cache = nil

function M.update()
  ---@type LazyPkgSource[]
  local sources = {}
  for _, s in ipairs(Config.options.pkg.sources) do
    sources[#sources + 1] = require("lazy.pkg." .. s)
  end

  M.cache = {}
  for _, plugin in pairs(Config.plugins) do
    if plugin._.installed then
      for _, source in ipairs(sources) do
        local spec = source.get(plugin)
        if spec then
          spec.name = plugin.name
          if type(spec.code) == "string" then
            spec.spec = { _raw = spec.code }
            spec.code = nil
          end
          M.cache[plugin.dir] = spec
          break
        end
      end
    end
  end
  local code = "return " .. Util.dump({ version = M.VERSION, specs = M.cache })
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
      local ret = chunk()
      if ret and ret.version == M.VERSION then
        M.cache = ret.specs
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
function M.get(dir)
  local ret = M.cache[dir]
  if not ret then
    return
  end

  if type(ret.spec) == "function" then
    ret.spec = ret.spec()
  end

  return ret
end

function M.spec()
  ---@type table<string,LazyPluginSpec>
  local ret = {}

  for dir in pairs(M.cache) do
    local pkg = M.get(dir)
    local spec = pkg and pkg.spec
    if pkg and spec then
      spec = type(spec) == "table" and vim.deepcopy(spec) or spec
      ---@cast spec LazySpec
      ret[dir] = { pkg.name, specs = spec }
    end
  end

  return ret
end

return setmetatable(M, {
  __index = function(_, key)
    if key == "cache" then
      _load()
      return M.cache
    end
  end,
})
