local Util = require("lazy.util")
local Git = require("lazy.manage.git")

---@type table<string, LazyTaskDef>
local M = {}

M.log = {
  skip = function(plugin, opts)
    if not (opts.interactive and Util.file_exists(plugin.dir .. "/.git")) then
      return false
    end
    return plugin._.updated and plugin._.updated.from == plugin._.updated.to
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

    if self.plugin._.updated then
      table.insert(args, self.plugin._.updated.from .. ".." .. (self.plugin._.updated.to or "HEAD"))
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
    if self.plugin._.is_local ~= self.plugin._.is_symlink then
      -- FIXME: should change here and in install
      error("incorrect local")
    end
    if self.plugin._.is_local then
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
        "--recurse-submodules",
        "--update-shallow",
        "--progress",
      }
      local git = assert(Git.info(self.plugin.dir))

      self:spawn("git", {
        args = args,
        cwd = self.plugin.dir,
        on_exit = function(ok)
          if ok then
            local git_new = assert(Git.info(self.plugin.dir))
            self.plugin._.updated = {
              from = git.commit,
              to = git_new.commit,
            }
            self.plugin._.dirty = not vim.deep_equal(git, git_new)
          end
        end,
      })
    end
  end,
}

M.install = {
  run = function(self)
    if self.plugin._.is_local then
      vim.loop.fs_symlink(self.plugin.uri, self.plugin.dir, { dir = true })
      vim.opt.runtimepath:append(self.plugin.uri)
    else
      local args = {
        "clone",
        self.plugin.uri,
        "--filter=blob:none",
        "--recurse-submodules",
        "--single-branch",
        "--shallow-submodules",
        "--no-checkout",
        "--progress",
      }

      if self.plugin.branch then
        vim.list_extend(args, { "-b", self.plugin.branch })
      end

      table.insert(args, self.plugin.dir)
      self:spawn("git", {
        args = args,
        on_exit = function(ok)
          if ok then
            self.plugin._.installed = true
            self.plugin._.dirty = true
          end
        end,
      })
    end
  end,
}
return M
