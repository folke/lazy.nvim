local Config = require("lazy.core.config")
local Util = require("lazy.util")

local M = {}

---@alias LazyPkgSpec LazySpec | fun():LazySpec

---@class LazyPkg
---@field source string
---@field file string
---@field spec? LazySpec
---@field chunk? string|fun():LazySpec

---@class LazyPkgSource
---@field get fun(plugin:LazyPlugin):LazyPkg

---@type table<string, LazyPkg>?
M.cache = nil

function M.update()
  ---@type LazyPkgSource[]
  local sources = {}
  for _, s in ipairs(Config.options.pkg.sources) do
    sources[#sources + 1] = require("lazy.pkg." .. s)
  end

  ---@type table<string, LazyPkg>
  local ret = {}
  for _, plugin in pairs(Config.plugins) do
    for _, source in ipairs(sources) do
      local spec = source.get(plugin)
      if spec then
        if type(spec.chunk) == "function" then
          spec.chunk = string.dump(spec.chunk)
        end
        ret[plugin.dir] = spec
        break
      end
    end
  end
  local code = "return " .. Util.dump(ret)
  Util.write_file(Config.options.pkg.cache, code)
  M.cache = nil
end

local function _load()
  Util.track("pkg")
  M.cache = {}
  if vim.uv.fs_stat(Config.options.pkg.cache) then
    Util.try(function()
      local chunk, err = loadfile(Config.options.pkg.cache)
      if not chunk then
        error(err)
      end
      M.cache = chunk()
    end, "Error loading pkg:")
  end
  Util.track()
end

---@param plugin LazyPlugin
---@return LazyPkg?
function M.get(plugin)
  if not M.cache then
    _load()
  end

  local ret = M.cache[plugin.dir]
  if not ret then
    return
  end

  if ret.chunk and not ret.spec then
    if type(ret.chunk) == "string" then
      ret.chunk = load(ret.chunk, "@" .. plugin.dir)
    end
    ret.spec = ret.chunk()
    ret.chunk = nil
  end

  return ret
end

---@param plugin LazyPlugin
---@return LazySpec?
function M.get_spec(plugin)
  local pkg = M.get(plugin)
  local spec = pkg and pkg.spec
  return spec and type(spec) == "table" and vim.deepcopy(spec) or spec
end

return M
