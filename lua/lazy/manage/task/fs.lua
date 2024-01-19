local Config = require("lazy.core.config")
local Util = require("lazy.util")

---@type table<string, LazyTaskDef>
local M = {}

M.clean = {
  skip = function(plugin)
    return plugin._.is_local
  end,
  run = function(self)
    local dir = self.plugin.dir:gsub("/+$", "")
    assert(dir:find(Config.options.root, 1, true) == 1, self.plugin.dir .. " should be under packpath!")

    local stat = vim.loop.fs_lstat(dir)
    assert(stat and stat.type == "directory", self.plugin.dir .. " should be a directory!")

    Util.walk(dir, function(path, _, type)
      if type == "directory" then
        vim.loop.fs_rmdir(path)
      else
        vim.loop.fs_unlink(path)
      end
    end)
    vim.loop.fs_rmdir(dir)

    self.plugin._.installed = false
  end,
}

return M
