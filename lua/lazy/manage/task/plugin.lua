local Util = require("lazy.util")
local Loader = require("lazy.core.loader")

---@type table<string, LazyTaskDef>
local M = {}

M.run = {
  skip = function(plugin)
    return not (plugin._.dirty and (plugin.opt == false or plugin.run))
  end,
  run = function(self)
    Loader.load(self.plugin, { task = "run" }, { load_start = true })

    local run = self.plugin.run
    if run then
      if type(run) == "string" and run:sub(1, 1) == ":" then
        local cmd = vim.api.nvim_parse_cmd(run:sub(2), {})
        self.output = vim.api.nvim_cmd(cmd, { output = true })
      elseif type(run) == "function" then
        run()
      else
        local args = vim.split(run, "%s+")
        return self:spawn(table.remove(args, 1), {
          args = args,
          cwd = self.plugin.dir,
        })
      end
    end
  end,
}

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

M.docs = {
  skip = function(plugin)
    return not plugin._.dirty
  end,
  run = function(self)
    local docs = self.plugin.dir .. "/doc/"
    if Util.file_exists(docs) then
      self.output = vim.api.nvim_cmd({ cmd = "helptags", args = { docs } }, { output = true })
    end
  end,
}

return M
