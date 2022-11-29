local Util = require("lazy.util")
local Git = require("lazy.manage.git")
local Lock = require("lazy.manage.lock")

---@type table<string, LazyTaskDef>
local M = {}

M.log = {
  ---@param opts {since?: string, updated?:boolean, check?: boolean}
  skip = function(plugin, opts)
    if opts.updated and not (plugin._.updated and plugin._.updated.from ~= plugin._.updated.to) then
      return true
    end
    return not Util.file_exists(plugin.dir .. "/.git")
  end,
  ---@param opts {since?: string, updated?:boolean, check?:boolean}
  run = function(self, opts)
    local args = {
      "log",
      "--pretty=format:%h %s (%cr)",
      "--abbrev-commit",
      "--decorate",
      "--date=short",
      "--color=never",
    }

    if opts.updated then
      table.insert(args, self.plugin._.updated.from .. ".." .. (self.plugin._.updated.to or "HEAD"))
    elseif opts.check then
      local info = assert(Git.info(self.plugin.dir))
      local target = assert(Git.get_target(self.plugin))
      table.insert(args, info.commit .. ".." .. target.commit)
    elseif opts.since then
      table.insert(args, "--since=" .. (opts.since or "3 days ago"))
    else
      table.insert(args, "-10")
    end

    self:spawn("git", {
      args = args,
      cwd = self.plugin.dir,
    })
  end,
}

M.clone = {
  skip = function(plugin)
    return plugin._.installed or plugin._.is_local
  end,
  run = function(self)
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
          self.plugin._.cloned = true
          self.plugin._.installed = true
          self.plugin._.dirty = true
        end
      end,
    })
  end,
}

M.branch = {
  skip = function(plugin)
    if not plugin._.installed or plugin._.is_local then
      return true
    end
    local branch = assert(Git.get_branch(plugin))
    return branch and branch.commit
  end,
  run = function(self)
    local branch = assert(Git.get_branch(self.plugin))
    local args = {
      "remote",
      "set-branches",
      "--add",
      "origin",
      branch.branch,
    }

    self:spawn("git", {
      args = args,
      cwd = self.plugin.dir,
    })
  end,
}

M.fetch = {
  skip = function(plugin)
    return not plugin._.installed or plugin._.is_local
  end,
  run = function(self)
    local args = {
      "fetch",
      "--recurse-submodules",
      "--update-shallow",
      "--progress",
    }

    self:spawn("git", {
      args = args,
      cwd = self.plugin.dir,
    })
  end,
}

M.checkout = {
  skip = function(plugin)
    return not plugin._.installed or plugin._.is_local
  end,
  ---@param opts {lockfile?:boolean}
  run = function(self, opts)
    local info = assert(Git.info(self.plugin.dir))
    local target = assert(Git.get_target(self.plugin))

    -- if the plugin is locked and we did not just clone it,
    -- then don't update
    if self.plugin.lock and not self.plugin._.cloned then
      target = info
    end

    local lock
    if opts.lockfile then
      lock = Lock.get(self.plugin)
      if lock then
        ---@diagnostic disable-next-line: cast-local-type
        target = lock
      end
    end

    if not self.plugin._.cloned and info.commit == target.commit and info.branch == target.branch then
      self.plugin._.updated = {
        from = info.commit,
        to = info.commit,
      }
      return
    end

    local args = {
      "checkout",
      "--progress",
    }

    if lock then
      table.insert(args, lock.commit)
    elseif target.tag then
      table.insert(args, "tags/" .. target.tag)
    elseif self.plugin.commit then
      table.insert(args, self.plugin.commit)
    elseif target.branch then
      table.insert(args, target.branch)
    end

    self:spawn("git", {
      args = args,
      cwd = self.plugin.dir,
      on_exit = function(ok)
        if ok then
          local new_info = assert(Git.info(self.plugin.dir))
          if not self.plugin._.cloned then
            self.plugin._.updated = {
              from = info.commit,
              to = new_info.commit,
            }
          end
          self.plugin._.dirty = true
        end
      end,
    })
  end,
}
return M
