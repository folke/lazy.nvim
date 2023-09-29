local Util = require("lazy.util")
local Loader = require("lazy.core.loader")

---@type table<string, LazyTaskDef>
local M = {}

M.build = {
  ---@param opts? {force:boolean}
  skip = function(plugin, opts)
    if opts and opts.force then
      return false
    end
    return not (plugin._.dirty and plugin.build)
  end,
  run = function(self)
    vim.cmd([[silent! runtime plugin/rplugin.vim]])

    Loader.load(self.plugin, { task = "build" })

    local builders = type(self.plugin.build) == "table" and self.plugin.build or { self.plugin.build }
    ---@cast builders (string|fun(LazyPlugin))[]

    for _, build in ipairs(builders) do
      if type(build) == "function" then
        build(self.plugin)
      elseif type(build) ~= "string" then
        error("invalid build type: " .. type(build))
      elseif
        vim.list_contains({ "vim", "lua" }, build:sub(-3)) and vim.loop.fs_stat(self.plugin.dir .. "/" .. build)
      then
        Loader.source(self.plugin.dir .. "/" .. build)
      elseif build:sub(1, 1) == ":" then
        local cmd = vim.api.nvim_parse_cmd(build:sub(2), {})
        self.output = vim.api.nvim_cmd(cmd, { output = true })
      else
        local shell = vim.env.SHELL or vim.o.shell
        local shell_args = shell:find("cmd.exe", 1, true) and "/c" or "-c"

        self:spawn(shell, {
          args = { shell_args, build },
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
