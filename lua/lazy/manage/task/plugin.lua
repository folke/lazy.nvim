local Loader = require("lazy.core.loader")
local Rocks = require("lazy.pkg.rockspec")
local Util = require("lazy.util")

---@type table<string, LazyTaskDef>
local M = {}

---@param plugin LazyPlugin
local function get_build_file(plugin)
  for _, path in ipairs({ "build.lua", "build/init.lua" }) do
    if Util.file_exists(plugin.dir .. "/" .. path) then
      return path
    end
  end
end

local B = {}

---@param task LazyTask
---@param build string
function B.cmd(task, build)
  if task.plugin.build ~= "rockspec" then
    Loader.load(task.plugin, { task = "build" })
  end
  local cmd = vim.api.nvim_parse_cmd(build:sub(2), {}) --[[@as vim.api.keyset.cmd]]
  task:log(vim.api.nvim_cmd(cmd, { output = true }))
end

---@async
---@param task LazyTask
---@param build string
function B.shell(task, build)
  local shell = vim.env.SHELL or vim.o.shell
  local shell_args = shell:find("cmd.exe", 1, true) and "/c" or "-c"

  task:spawn(shell, {
    args = { shell_args, build },
    cwd = task.plugin.dir,
  })
end

M.build = {
  ---@param opts? {force:boolean}
  skip = function(plugin, opts)
    if opts and opts.force then
      return false
    end
    return not ((plugin._.dirty or plugin._.build) and (plugin.build or get_build_file(plugin)))
  end,
  ---@async
  run = function(self)
    vim.cmd([[silent! runtime plugin/rplugin.vim]])

    local builders = self.plugin.build

    -- Skip if `build` is set to `false`
    if builders == false then
      return
    end

    builders = builders or get_build_file(self.plugin)

    if builders then
      builders = type(builders) == "table" and builders or { builders }
      ---@cast builders (string|fun(LazyPlugin))[]
      for _, build in ipairs(builders) do
        if type(build) == "function" then
          build(self.plugin)
        elseif build == "rockspec" then
          Rocks.build(self)
        elseif build:sub(1, 1) == ":" then
          B.cmd(self, build)
        elseif build:match("%.lua$") then
          local file = self.plugin.dir .. "/" .. build
          local chunk, err = loadfile(file)
          if not chunk or err then
            error(err)
          end
          chunk()
        else
          B.shell(self, build)
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
    local docs = self.plugin.dir .. "/doc"
    if Util.file_exists(docs) then
      self:log(vim.api.nvim_cmd({ cmd = "helptags", args = { docs } }, { output = true }))
    end
  end,
}

return M
