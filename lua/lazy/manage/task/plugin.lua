local Util = require("lazy.util")
local Loader = require("lazy.core.loader")

---@type table<string, LazyTaskDef>
local M = {}

M.build = {
  skip = function(plugin)
    return not (plugin._.dirty and plugin.build)
  end,
  run = function(self)
    Loader.load(self.plugin, { task = "build" })

    local build = self.plugin.build
    if build then
      if type(build) == "string" and build:sub(1, 1) == ":" then
        local cmd = vim.api.nvim_parse_cmd(build:sub(2), {})
        self.output = vim.api.nvim_cmd(cmd, { output = true })
      elseif type(build) == "function" then
        build()
      else
        local args = vim.split(build, "%s+")
        return self:spawn(table.remove(args, 1), {
          args = args,
          cwd = self.plugin.dir,
        })
      end
    end
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
