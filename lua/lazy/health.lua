local Config = require("lazy.core.config")
local Process = require("lazy.manage.process")
local uv = vim.uv or vim.loop

local M = {}

-- "report_" prefix has been deprecated, use the recommended replacements if they exist.
local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local warn = vim.health.warn or vim.health.report_warn
local error = vim.health.error or vim.health.report_error
local info = vim.health.info or vim.health.report_info

---@class LazyHealth
---@field error? fun(msg:string)
---@field warn? fun(msg:string)
---@field ok? fun(msg:string)

---@class LazyHealthHave : LazyHealth
---@field version? string
---@field version_pattern? string
---@field optional? boolean

---@param cmd string|string[]
---@param opts? LazyHealthHave
function M.have(cmd, opts)
  opts = vim.tbl_extend("force", {
    error = error,
    warn = warn,
    ok = ok,
    version = "--version",
  }, opts or {})

  cmd = type(cmd) == "table" and cmd or { cmd }
  ---@cast cmd string[]
  ---@type string?
  local found
  for _, c in ipairs(cmd) do
    if vim.fn.executable(c) == 1 then
      local out, exit_code = Process.exec({ c, opts.version })
      if exit_code ~= 0 then
        opts.error(("failed to get version of {%s}\n%s"):format(c, table.concat(out, "\n")))
      else
        local version = vim.trim(out[1] or "")
        version = version:gsub("^%s*" .. vim.pesc(c) .. "%s*", "")
        if opts.version_pattern and not version:find(opts.version_pattern, 1, true) then
          opts.warn(("`%s` version `%s` needed, but found `%s`"):format(c, opts.version_pattern, version))
        else
          found = ("{%s} `%s`"):format(c, version)
          break
        end
      end
    end
  end
  if found then
    opts.ok(found)
    return true
  else
    (opts.optional and opts.warn or opts.error)(
      ("{%s} %snot installed"):format(
        table.concat(cmd, "} or {"),
        opts.version_pattern and "version `" .. opts.version_pattern .. "` " or ""
      )
    )
  end
end

function M.check()
  start("lazy.nvim")
  info("{lazy.nvim} version `" .. Config.version .. "`")

  M.have("git")

  local sites = vim.opt.packpath:get()
  local default_site = vim.fn.stdpath("data") .. "/site"
  if not vim.tbl_contains(sites, default_site) then
    sites[#sites + 1] = default_site
  end

  local existing = false
  for _, site in pairs(sites) do
    for _, packs in ipairs(vim.fn.expand(site .. "/pack/*", false, true)) do
      if not packs:find("[/\\]dist$") and uv.fs_stat(packs) then
        existing = true
        warn("found existing packages at `" .. packs .. "`")
      end
    end
  end
  if not existing then
    ok("no existing packages found by other package managers")
  end

  for _, name in ipairs({ "packer", "plugged", "paq", "pckr", "mini.deps" }) do
    for _, path in ipairs(vim.opt.rtp:get()) do
      if path:find(name, 1, true) then
        error("Found paths on the rtp from another plugin manager `" .. name .. "`")
        break
      end
    end
  end

  local packer_compiled = vim.fn.stdpath("config") .. "/plugin/packer_compiled.lua"
  if uv.fs_stat(packer_compiled) then
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

  start("luarocks")
  if Config.options.rocks.enabled then
    if Config.hererocks() then
      info("checking `hererocks` installation")
    else
      info("checking `luarocks` installation")
    end
    local need_luarocks = {}
    for _, plugin in pairs(spec.plugins) do
      if plugin.build == "rockspec" then
        table.insert(need_luarocks, plugin.name)
      end
    end
    if #need_luarocks == 0 then
      ok("no plugins require `luarocks`, so you can ignore any warnings below")
    else
      local lines = vim.tbl_map(function(name)
        return "  * `" .. name .. "`"
      end, need_luarocks)

      info("you have some plugins that require `luarocks`:\n" .. table.concat(lines, "\n"))
    end
    local ok = require("lazy.pkg.rockspec").check({
      error = #need_luarocks > 0 and error or warn,
      warn = warn,
      ok = ok,
    })
    if not ok then
      warn(table.concat({
        "Lazy won't be able to install plugins that require `luarocks`.",
        "Here's what you can do:",
        " - fix your `luarocks` installation",
        Config.hererocks() and " - disable *hererocks* with `opts.rocks.hererocks = false`"
          or " - enable `hererocks` with `opts.rocks.hererocks = true`",
        " - disable `luarocks` support completely with `opts.rocks.enabled = false`",
      }, "\n"))
    end
  else
    ok("luarocks disabled")
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
