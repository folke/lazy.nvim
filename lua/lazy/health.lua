local Config = require("lazy.core.config")

local M = {}

function M.check()
  vim.health.report_start("lazy.nvim")

  if vim.fn.executable("git") == 1 then
    vim.health.report_ok("Git installed")
  else
    vim.health.report_error("Git not installd?")
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
        vim.health.report_warn("found existing packages at `" .. packs .. "`")
      end
    end
  end
  if not existing then
    vim.health.report_ok("no existing packages found by other package managers")
  end

  local packer_compiled = vim.fn.stdpath("config") .. "/plugin/packer_compiled.lua"
  if vim.loop.fs_stat(packer_compiled) then
    vim.health.report_error("please remove the file `" .. packer_compiled .. "`")
  else
    vim.health.report_ok("packer_compiled.lua not found")
  end

  local spec = Config.spec
  for _, plugin in pairs(spec.plugins) do
    M.check_valid(plugin)
    M.check_override(plugin)
  end
  if #spec.notifs > 0 then
    vim.health.report_error("Issues were reported when loading your specs:")
    for _, notif in ipairs(spec.notifs) do
      local lines = vim.split(notif.msg, "\n")
      for _, line in ipairs(lines) do
        if notif.level == vim.log.levels.ERROR then
          vim.health.report_error(line)
        else
          vim.health.report_warn(line)
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
        vim.health.report_warn("{" .. plugin.name .. "}: unknown key <" .. key .. ">")
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
  local skip = { "dependencies", "_", "opts" }
  vim.list_extend(skip, vim.tbl_values(Handler.types))

  for key, value in pairs(plugin._.super) do
    if not vim.tbl_contains(skip, key) and plugin[key] and plugin[key] ~= value then
      vim.health.report_warn("{" .. plugin.name .. "}: overriding <" .. key .. ">")
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
  "module",
  "name",
  "opts",
  "pin",
  "priority",
  "tag",
  "url",
  "version",
}

return M
