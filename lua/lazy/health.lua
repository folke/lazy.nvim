local Util = require("lazy.util")
local Config = require("lazy.core.config")

local M = {}

function M.check()
  vim.health.report_start("lazy.nvim")

  local existing = false
  Util.ls(vim.fn.stdpath("data") .. "/site/pack/", function(path)
    existing = true
    vim.health.report_warn("found existing packages at `" .. path .. "`")
  end)
  if not existing then
    vim.health.report_ok("no existing packages found by other package managers")
  end

  local packer_compiled = vim.fn.stdpath("config") .. "/plugin/packer_compiled.lua"
  if vim.loop.fs_stat(packer_compiled) then
    vim.health.report_error("please remove the file `" .. packer_compiled .. "`")
  else
    vim.health.report_ok("packer_compiled.lua not found")
  end

  local valid = {
    1,
    "name",
    "url",
    "enabled",
    "lazy",
    "dev",
    "dependencies",
    "init",
    "config",
    "build",
    "branch",
    "tag",
    "commit",
    "version",
    "module",
    "pin",
    "cmd",
    "event",
    "keys",
    "ft",
    "dir",
    "priority",
    "_",
  }
  for _, plugin in pairs(Config.plugins) do
    for key in pairs(plugin) do
      if not vim.tbl_contains(valid, key) then
        if key ~= "module" or type(plugin.module) ~= "boolean" then
          vim.health.report_warn("{" .. plugin.name .. "}: unknown key <" .. key .. ">")
        end
      end
    end
  end
end

return M
