local Util = require("lazy.util")

---@type table<string, LazyTaskDef>
local M = {}

M.log = {
  needed = function(plugin, opts)
    if opts.interactive ~= true or not Util.file_exists(plugin.dir .. "/.git") then
      return false
    end
    return plugin.updated == nil or plugin.updated.from ~= plugin.updated.to
  end,
  run = function(self)
    local args = {
      "log",
      "--pretty=format:%h %s (%cr)",
      "--abbrev-commit",
      "--decorate",
      "--date=short",
      "--color=never",
    }

    if self.plugin.updated then
      table.insert(args, self.plugin.updated.from .. ".." .. (self.plugin.updated.to or "HEAD"))
    else
      table.insert(args, "--since=7 days ago")
    end

    self:spawn("git", {
      args = args,
      cwd = self.plugin.dir,
    })
  end,
}

M.update = {
  run = function(self)
    if Util.file_exists(self.plugin.uri) then
      if vim.loop.fs_realpath(self.plugin.uri) ~= vim.loop.fs_realpath(self.plugin.dir) then
        vim.loop.fs_unlink(self.plugin.dir)
        vim.loop.fs_symlink(self.plugin.uri, self.plugin.dir, {
          dir = true,
        })
        vim.opt.runtimepath:append(self.plugin.uri)
      end
    else
      local args = {
        "pull",
        "--tags",
        "--recurse-submodules",
        "--update-shallow",
        "--progress",
      }
      local git = assert(Util.git_info(self.plugin.dir))

      self:spawn("git", {
        args = args,
        cwd = self.plugin.dir,
        on_exit = function(ok)
          if ok then
            local git_new = assert(Util.git_info(self.plugin.dir))
            self.plugin.updated = {
              from = git.hash,
              to = git_new.hash,
            }
            self.plugin.dirty = not vim.deep_equal(git, git_new)
          end
        end,
      })
    end
  end,
}

M.install = {
  run = function(self)
    if Util.file_exists(self.plugin.uri) then
      vim.loop.fs_symlink(self.plugin.uri, self.plugin.dir, {
        dir = true,
      })
      vim.opt.runtimepath:append(self.plugin.uri)
    else
      local args = {
        "clone",
        self.plugin.uri,
        -- "--depth=1",
        "--filter=blob:none",
        -- "--filter=tree:0",
        "--recurse-submodules",
        "--single-branch",
        "--shallow-submodules",
        "--progress",
      }

      if self.plugin.branch then
        vim.list_extend(args, {
          "-b",
          self.plugin.branch,
        })
      end

      table.insert(args, self.plugin.dir)
      self:spawn("git", {
        args = args,
        on_exit = function(ok)
          if ok then
            self.plugin.installed = true
            self.plugin.dirty = true
          end
        end,
      })
    end
  end,
}
return M
