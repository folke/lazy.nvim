local Config = require("lazy.core.config")
local Loader = require("lazy.core.loader")
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
function B.rockspec(task)
  ---@type table<string, string>
  local env = {}

  if Config.options.rocks.hererocks then
    local hererocks = Config.options.rocks.root .. "/hererocks"
    local sep = jit.os:find("Windows") and ";" or ":"
    local path = vim.split(vim.env.PATH, sep)
    table.insert(path, 1, hererocks .. "/bin")
    env = {
      PATH = table.concat(path, sep),
    }
    local plugin = Config.plugins.hererocks
    -- hererocks is still building, so skip for now
    if plugin and plugin._.build then
      return
    end
  end

  local root = Config.options.rocks.root .. "/" .. task.plugin.name
  task:spawn("luarocks", {
    args = {
      "--tree",
      root,
      "--server",
      Config.options.rocks.server,
      "--dev",
      "--lua-version",
      "5.1",
      "make",
      "--force-fast",
    },
    cwd = task.plugin.dir,
    env = env,
  })
end

---@param task LazyTask
---@param build string
function B.cmd(task, build)
  local cmd = vim.api.nvim_parse_cmd(build:sub(2), {}) --[[@as vim.api.keyset.cmd]]
  task.output = vim.api.nvim_cmd(cmd, { output = true })
end

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
  run = function(self)
    vim.cmd([[silent! runtime plugin/rplugin.vim]])

    if self.plugin.build ~= "rockspec" then
      Loader.load(self.plugin, { task = "build" })
    end

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
          self:async(function()
            build(self.plugin)
          end)
        elseif build == "rockspec" then
          B.rockspec(self)
        elseif build:sub(1, 1) == ":" then
          B.cmd(self, build)
        elseif build:match("%.lua$") then
          local file = self.plugin.dir .. "/" .. build
          local chunk, err = loadfile(file)
          if not chunk or err then
            error(err)
          end
          self:async(chunk)
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
    local docs = self.plugin.dir .. "/doc/"
    if Util.file_exists(docs) then
      self.output = vim.api.nvim_cmd({ cmd = "helptags", args = { docs } }, { output = true })
    end
  end,
}

return M
