local Config = require("lazy.core.config")

local M = {}

-- "report_" prefix has been deprecated, use the recommended replacements if they exist.
local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local warn = vim.health.warn or vim.health.report_warn
local error = vim.health.error or vim.health.report_error

function M.check()
  start("lazy.nvim")

  if vim.fn.executable("git") == 1 then
    ok("Git installed")
  else
    error("Git not installed?")
  end

  local sites = vim.opt.packpath:get()
  local default_site = vim.fn.stdpath("data") .. "/site"
  if not vim.tbl_contains(sites, default_site) then
    sites[#sites + 1] = default_site
  end

  local existing = false
  for _, site in pairs(sites) do
    for _, packs in ipairs(vim.fn.expand(site .. "/pack/*", false, true)) do
      if not packs:find("[/\\]dist$") and vim.loop.fs_stat(packs) then
        existing = true
        warn("found existing packages at `" .. packs .. "`")
      end
    end
  end
  if not existing then
    ok("no existing packages found by other package managers")
  end

  for _, name in ipairs({ "packer", "plugged", "paq" }) do
    for _, path in ipairs(vim.opt.rtp:get()) do
      if path:find(name, 1, true) then
        error("Found paths on the rtp from another plugin manager `" .. name .. "`")
        break
      end
    end
  end

  local packer_compiled = vim.fn.stdpath("config") .. "/plugin/packer_compiled.lua"
  if vim.loop.fs_stat(packer_compiled) then
    error("please remove the file `" .. packer_compiled .. "`")
  else
    ok("packer_compiled.lua not found")
  end

  local spec = Config.spec
  if spec == nil then
    error('No plugins loaded. Did you forget to run `require("lazy").setup()`?')
  else
    for _, plugin in pairs(spec.plugins) do
      M.check_valid(plugin)
      M.check_override(plugin)
    end
    if #spec.notifs > 0 then
      error("Issues were reported when loading your specs:")
      for _, notif in ipairs(spec.notifs) do
        local lines = vim.split(notif.msg, "\n")
        for _, line in ipairs(lines) do
          if notif.level == vim.log.levels.ERROR then
            error(line)
          else
            warn(line)
          end
        end
      end
    end
  end
end

---@param plugin LazyPlugin
function M.check_valid(plugin)
  for key in pairs(plugin) do
    if not vim.tbl_contains(M.valid, key) then
      if key ~= "module" or type(plugin.module) ~= "boolean" then
        warn("{" .. plugin.name .. "}: unknown key <" .. key .. ">")
      end
    end
  end
end

---@param plugin LazyPlugin
function M.check_override(plugin)
  if not plugin._.super then
    return
  end

  local Handler = require("lazy.core.handler")
  local skip = { "dependencies", "_", "opts", 1 }
  vim.list_extend(skip, vim.tbl_values(Handler.types))

  for key, value in pairs(plugin._.super) do
    if not vim.tbl_contains(skip, key) and plugin[key] and plugin[key] ~= value then
      warn("{" .. plugin.name .. "}: overriding <" .. key .. ">")
    end
  end
end

M.valid = {
  1,
  "_",
  "branch",
  "build",
  "cmd",
  "commit",
  "cond",
  "config",
  "deactivate",
  "dependencies",
  "dev",
  "dir",
  "enabled",
  "event",
  "ft",
  "import",
  "init",
  "keys",
  "lazy",
  "main",
  "module",
  "name",
  "optional",
  "opts",
  "pin",
  "priority",
  "submodules",
  "tag",
  "url",
  "version",
}

return M
