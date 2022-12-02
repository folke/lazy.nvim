local Util = require("lazy.util")

---@type table<string, LazyTaskDef>
local M = {}

M.clean = {
  run = function(self)
    local dir = self.plugin.dir:gsub("/+$", "")
    local stat = vim.loop.fs_lstat(dir)

    if stat.type == "directory" then
      Util.walk(dir, function(path, _, type)
        if type == "directory" then
          vim.loop.fs_rmdir(path)
        else
          vim.loop.fs_unlink(path)
        end
      end)
      vim.loop.fs_rmdir(dir)
    else
      vim.loop.fs_unlink(dir)
    end

    self.plugin._.installed = false
  end,
}

M.symlink = {
  skip = function(plugin)
    if not plugin._.is_local then
      return true
    end
    return not plugin._.is_symlink and plugin._.installed
  end,
  run = function(self)
    local stat = vim.loop.fs_lstat(self.plugin.dir)
    if stat then
      if vim.loop.fs_realpath(self.plugin.uri) == vim.loop.fs_realpath(self.plugin.dir) then
        self.plugin._.installed = true
        return
      else
        vim.loop.fs_unlink(self.plugin.dir)
      end
    end
    vim.loop.fs_symlink(self.plugin.uri, self.plugin.dir, { dir = true })
    vim.opt.runtimepath:append(self.plugin.uri)
    self.plugin._.installed = true
    self.plugin._.cloned = true
  end,
}

return M
