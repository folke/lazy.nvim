local Config = require("lazy.core.config")
local Util = require("lazy.util")

---@class PackSpec
---@field dependencies? table<string, string>
---@field lazy? LazyPluginSpec
local M = {}

M.lazy_file = "lazy.lua"
M.pkg_file = "pkg.json"
M.enable_lazy_file = false

---@alias LazyPkg {lazy?:(fun():LazySpec), pkg?:PackSpec}

---@type table<string, LazyPkg>
M.packspecs = nil
---@type table<string, LazySpec>
M.specs = {}

---@param spec LazyPkg
---@param plugin LazyPlugin
---@return LazySpec?
local function convert(plugin, spec)
  ---@type LazySpec
  local ret = {}

  local pkg = spec.pkg
  if pkg then
    if pkg.dependencies then
      for url, version in pairs(pkg.dependencies) do
        if (not Config.options.packspec.versions) or version == "*" or version == "" then
          version = nil
        end
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
  end

  if spec.lazy then
    ret[#ret + 1] = spec.lazy()
  end

  return ret
end

local function load()
  Util.track("packspec")
  M.packspecs = {}
  if vim.loop.fs_stat(Config.options.packspec.path) then
    Util.try(function()
      M.packspecs = loadfile(Config.options.packspec.path)()
    end, "Error loading packspecs:")
  end
  Util.track()
end

---@param plugin LazyPlugin
---@return LazySpec?
function M.get(plugin)
  if not M.packspecs then
    load()
  end

  if not M.packspecs[plugin.dir] then
    return
  end
  M.specs[plugin.dir] = M.specs[plugin.dir] or convert(plugin, M.packspecs[plugin.dir])
  return vim.deepcopy(M.specs[plugin.dir])
end

function M.update()
  local ret = {}
  for _, plugin in pairs(Config.plugins) do
    local spec = {
      pkg = M.pkg(plugin),
      lazy = M.enable_lazy_file and M.lazy_pkg(plugin) or nil,
    }
    if not vim.tbl_isempty(spec) then
      ret[plugin.dir] = spec
    end
  end
  local code = "return " .. Util.dump(ret)
  Util.write_file(Config.options.packspec.path, code)
  M.packspecs = nil
  M.specs = {}
end

---@param plugin LazyPlugin
function M.lazy_pkg(plugin)
  local file = Util.norm(plugin.dir .. "/" .. M.lazy_file)
  if Util.file_exists(file) then
    ---@type LazySpec
    local chunk = Util.try(function()
      return loadfile(file)
    end, "`" .. M.lazy_file .. "` for **" .. plugin.name .. "** has errors:")
    if chunk then
      return { _raw = ([[function() %s end]]):format(Util.read_file(file)) }
    else
      Util.error("Invalid `package.lua` for **" .. plugin.name .. "**")
    end
  end
end

---@param plugin LazyPlugin
function M.pkg(plugin)
  local file = Util.norm(plugin.dir .. "/" .. M.pkg_file)
  if Util.file_exists(file) then
    ---@type PackSpec
    return Util.try(function()
      return vim.json.decode(Util.read_file(file))
    end, "`" .. M.pkg_file .. "` for **" .. plugin.name .. "** has errors:")
  end
end

return M
