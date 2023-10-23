local Config = require("lazy.core.config")
local Git = require("lazy.manage.git")
local Lock = require("lazy.manage.lock")
local Util = require("lazy.util")

---@type table<string, LazyTaskDef>
local M = {}

M.log = {
  ---@param opts {updated?:boolean, check?: boolean}
  skip = function(plugin, opts)
    if opts.check and plugin.pin then
      return true
    end
    if opts.updated and not (plugin._.updated and plugin._.updated.from ~= plugin._.updated.to) then
      return true
    end
    local stat = vim.loop.fs_stat(plugin.dir .. "/.git")
    return not (stat and stat.type == "directory")
  end,
  ---@param opts {args?: string[], updated?:boolean, check?:boolean}
  run = function(self, opts)
    local args = {
      "log",
      "--pretty=format:%h %s (%cr)",
      "--abbrev-commit",
      "--decorate",
      "--date=short",
      "--color=never",
      "--no-show-signature",
    }

    if opts.updated then
      table.insert(args, self.plugin._.updated.from .. ".." .. (self.plugin._.updated.to or "HEAD"))
    elseif opts.check then
      local info = assert(Git.info(self.plugin.dir))
      local target = assert(Git.get_target(self.plugin))
      if not target.commit then
        for k, v in pairs(target) do
          error(k .. " '" .. v .. "' not found")
        end
        error("no target commit found")
      end
      assert(target.commit, self.plugin.name .. " " .. target.branch)
      if Git.eq(info, target) then
        if Config.options.checker.check_pinned then
          local last_commit = Git.get_commit(self.plugin.dir, target.branch, true)
          if not Git.eq(info, { commit = last_commit }) then
            self.plugin._.outdated = true
          end
        end
      else
        self.plugin._.updates = { from = info, to = target }
      end
      table.insert(args, info.commit .. ".." .. target.commit)
    else
      vim.list_extend(args, opts.args or Config.options.git.log)
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
      self.plugin.url,
    }

    if Config.options.git.filter then
      args[#args + 1] = "--filter=blob:none"
    end

    if self.plugin.submodules ~= false then
      args[#args + 1] = "--recurse-submodules"
    end

    args[#args + 1] = "--origin=origin"

    args[#args + 1] = "--progress"

    if self.plugin.branch then
      vim.list_extend(args, { "-b", self.plugin.branch })
    end

    table.insert(args, self.plugin.dir)

    if vim.fn.isdirectory(self.plugin.dir) == 1 then
      require("lazy.manage.task.fs").clean.run(self, {})
    end

    local marker = self.plugin.dir .. ".cloning"
    Util.write_file(marker, "")

    self:spawn("git", {
      args = args,
      on_exit = function(ok)
        if ok then
          self.plugin._.cloned = true
          self.plugin._.installed = true
          self.plugin._.dirty = true
          vim.loop.fs_unlink(marker)
        end
      end,
    })
  end,
}

-- setup origin branches if needed
-- fetch will retrieve the data
M.branch = {
  skip = function(plugin)
    if not plugin._.installed or plugin._.is_local then
      return true
    end
    local branch = assert(Git.get_branch(plugin))
    return Git.get_commit(plugin.dir, branch)
  end,
  run = function(self)
    local args = {
      "remote",
      "set-branches",
      "--add",
      "origin",
      assert(Git.get_branch(self.plugin)),
    }

    self:spawn("git", {
      args = args,
      cwd = self.plugin.dir,
    })
  end,
}

-- check and switch origin
M.origin = {
  skip = function(plugin)
    if not plugin._.installed or plugin._.is_local then
      return true
    end
    local origin = Git.get_origin(plugin.dir)
    return origin == plugin.url
  end,
  ---@param opts {check?:boolean}
  run = function(self, opts)
    if opts.check then
      local origin = Git.get_origin(self.plugin.dir)
      self.error = "Origin has changed:\n"
      self.error = self.error .. "  * old: " .. origin .. "\n"
      self.error = self.error .. "  * new: " .. self.plugin.url .. "\n"
      self.error = self.error .. "Please run update to fix"
      return
    end
    require("lazy.manage.task.fs").clean.run(self, opts)
    M.clone.run(self, opts)
  end,
}

M.status = {
  skip = function(plugin)
    return not plugin._.installed or plugin._.is_local
  end,
  run = function(self)
    self:spawn("git", {
      args = { "ls-files", "-d", "-m" },
      cwd = self.plugin.dir,
      on_exit = function(ok, output)
        if ok then
          local lines = vim.split(output, "\n")
          lines = vim.tbl_filter(function(line)
            -- Fix doc/tags being marked as modified
            if line:gsub("[\\/]", "/") == "doc/tags" then
              local Process = require("lazy.manage.process")
              Process.exec({ "git", "checkout", "--", "doc/tags" }, { cwd = self.plugin.dir })
              return false
            end
            return line ~= ""
          end, lines)
          if #lines > 0 then
            self.error = "You have local changes in `" .. self.plugin.dir .. "`:\n"
            for _, line in ipairs(lines) do
              self.error = self.error .. "  * " .. line .. "\n"
            end
            self.error = self.error .. "Please remove them to update.\n"
            self.error = self.error .. "You can also press `x` to remove the plugin and then `I` to install it again."
          end
        end
      end,
    })
  end,
}

-- fetches all needed origin branches
M.fetch = {
  skip = function(plugin)
    return not plugin._.installed or plugin._.is_local
  end,

  run = function(self)
    local args = {
      "fetch",
      "--recurse-submodules",
      "--tags", -- also fetch remote tags
      "--force", -- overwrite existing tags if needed
      "--progress",
    }

    if self.plugin.submodules == false then
      table.remove(args, 2)
    end

    self:spawn("git", {
      args = args,
      cwd = self.plugin.dir,
    })
  end,
}

-- checkout to the target commit
-- branches will exists at this point, so so will the commit
M.checkout = {
  skip = function(plugin)
    return not plugin._.installed or plugin._.is_local
  end,

  ---@param opts {lockfile?:boolean}
  run = function(self, opts)
    local info = assert(Git.info(self.plugin.dir))
    local target = assert(Git.get_target(self.plugin))

    -- if the plugin is pinned and we did not just clone it,
    -- then don't update
    if self.plugin.pin and not self.plugin._.cloned then
      target = info
    end

    local lock
    if opts.lockfile then
      -- restore to the lock if it exists
      lock = Lock.get(self.plugin)
      if lock then
        ---@diagnostic disable-next-line: cast-local-type
        target = lock
      end
    end

    -- dont run checkout if target is already reached.
    -- unless we just cloned, since then we won't have any data yet
    if Git.eq(info, target) and info.branch == target.branch then
      self.plugin._.updated = {
        from = info.commit,
        to = info.commit,
      }
      return
    end

    local args = {
      "checkout",
      "--progress",
      "--recurse-submodules",
    }

    if self.plugin.submodules == false then
      table.remove(args, 3)
    end

    if lock then
      table.insert(args, lock.commit)
    elseif target.tag then
      table.insert(args, "tags/" .. target.tag)
    elseif self.plugin.commit then
      table.insert(args, self.plugin.commit)
    else
      table.insert(args, target.commit)
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
            if self.plugin._.updated.from ~= self.plugin._.updated.to then
              self.plugin._.dirty = true
            end
          end
        end
      end,
    })
  end,
}
return M
