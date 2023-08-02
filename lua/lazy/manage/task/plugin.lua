local Util = require("lazy.util")
local Loader = require("lazy.core.loader")
local Config = require("lazy.core.config")

---@type table<string, LazyTaskDef>
local M = {}

---@param plugin LazyPlugin
local function get_build_file(plugin)
  for _, path in ipairs({ "build.lua", "build/init.lua" }) do
    path = plugin.dir .. "/" .. path
    if Util.file_exists(path) then
      return path
    end
  end
end

local function do_in_dir(dir, fn)
  local d = vim.loop.getcwd()
  vim.loop.chdir(dir)
  fn()
  vim.loop.chdir(d)
end

M.build = {
  ---@param opts? {force:boolean}
  skip = function(plugin, opts)
    if opts and opts.force then
      return false
    end
    return not (plugin._.dirty and (plugin.build or get_build_file(plugin)))
  end,
  run = function(self)
    vim.cmd([[silent! runtime plugin/rplugin.vim]])

    Loader.load(self.plugin, { task = "build" })

    local builders = self.plugin.build

    local build_file = get_build_file(self.plugin)
    if build_file then
      if builders then
        if Config.options.build.warn_on_override then
          Util.warn(
            ("Plugin **%s** provides its own build script, but you also defined a `build` command.\nThe `build.lua` file will not be used"):format(
              self.plugin.name
            )
          )
        end
      else
        builders = function()
          Loader.source(build_file)
        end
      end
    end
    if builders then
      builders = type(builders) == "table" and builders or { builders }
      ---@cast builders (string|fun(LazyPlugin))[]
      for _, build in ipairs(builders) do
        if type(build) == "string" and build:sub(1, 1) == ":" then
          local cmd = vim.api.nvim_parse_cmd(build:sub(2), {})
          do_in_dir(self.plugin.dir, function()
            self.output = vim.api.nvim_cmd(cmd, { output = true })
          end)
        elseif type(build) == "function" then
          do_in_dir(self.plugin.dir, function()
            build(self.plugin)
          end)
        else
          local shell = vim.env.SHELL or vim.o.shell
          local shell_args = shell:find("cmd.exe", 1, true) and "/c" or "-c"

          self:spawn(shell, {
            args = { shell_args, build },
            cwd = self.plugin.dir,
          })
        end
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
