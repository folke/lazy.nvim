local Util = require("lazy.util")

local M = {}

---@alias LazyDiff {commit:string} | {from:string, to:string}
---@alias LazyDiffFun fun(plugin:LazyPlugin, diff:LazyDiff)

M.handlers = {

  ---@type LazyDiffFun
  browser = function(plugin, diff)
    if plugin.url then
      local url = plugin.url:gsub("%.git$", "")
      if diff.commit then
        Util.open(url .. "/commit/" .. diff.commit)
      else
        Util.open(url .. "/compare/" .. diff.from .. ".." .. diff.to)
      end
    else
      Util.error("No url for " .. plugin.name)
    end
  end,

  ---@type LazyDiffFun
  ["diffview.nvim"] = function(plugin, diff)
    local args
    if diff.commit then
      args = ("-C=%s"):format(plugin.dir) .. " " .. diff.commit .. "^!"
    else
      args = ("-C=%s"):format(plugin.dir) .. " " .. diff.from .. ".." .. diff.to
    end
    vim.cmd("DiffviewOpen " .. args)
  end,

  ---@type LazyDiffFun
  git = function(plugin, diff)
    local cmd = { "git" }
    if diff.commit then
      cmd[#cmd + 1] = "show"
      cmd[#cmd + 1] = diff.commit
    else
      cmd[#cmd + 1] = "diff"
      cmd[#cmd + 1] = diff.from
      cmd[#cmd + 1] = diff.to
    end
    Util.float_cmd(cmd, { cwd = plugin.dir, filetype = "git" })
  end,

  ---@type LazyDiffFun
  terminal_git = function(plugin, diff)
    local cmd = { "git" }
    if diff.commit then
      cmd[#cmd + 1] = "show"
      cmd[#cmd + 1] = diff.commit
    else
      cmd[#cmd + 1] = "diff"
      cmd[#cmd + 1] = diff.from
      cmd[#cmd + 1] = diff.to
    end
    Util.float_term(cmd, { cwd = plugin.dir, interactive = false, env = { PAGER = "cat" } })
  end,
}

return M
