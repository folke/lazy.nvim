local Process = require("lazy.process")
local Loader = require("lazy.loader")

---@class LazyTask
---@field plugin LazyPlugin
---@field type TaskType
---@field running boolean
local Task = {}

---@alias TaskType "update"|"install"|"run"|"clean"

---@param plugin LazyPlugin
---@param type TaskType
function Task.new(plugin, type)
  local self = setmetatable({}, {
    __index = Task,
  })
  self.plugin = plugin
  self.type = type
  self.output = ""
  self.status = ""
  plugin.tasks = plugin.tasks or {}
  table.insert(plugin.tasks, self)
  return self
end

function Task:_done()
  self.running = false

  vim.cmd("do User LazyRender")
end

function Task:clean()
  local function rm(path)
    for _, entry in ipairs(Util.scandir(path)) do
      if entry.type == "directory" then
        rm(entry.path)
      else
        vim.loop.fs_unlink(entry.path)
      end
    end

    vim.loop.fs_rmdir(path)
  end

  local stat = vim.loop.fs_stat(self.plugin.dir)

  if stat.type == "directory" then
    rm(self.plugin.dir)
  else
    vim.loop.fs_unlink(self.plugin.dir)
  end

  self.plugin.installed = false
  self.running = false
end

function Task:install()
  if Util.file_exists(self.plugin.uri) then
    vim.loop.fs_symlink(self.plugin.uri, self.plugin.dir, {
      dir = true,
    })
    vim.opt.runtimepath:append(self.plugin.uri)
    self:_done()
  else
    local args = {
      "clone",
      self.plugin.uri,
      "--depth=1",
      "--recurse-submodules",
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
end

function Task:run()
  Loader.load(self.plugin)

  local run = self.plugin.run

  if run then
    if type(run) == "string" and run:sub(1, 1) == ":" then
      vim.cmd(run:sub(2))
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

  self:_done()
end

---@param cmd string
---@param opts ProcessOpts
function Task:spawn(cmd, opts)
  opts = opts or {}
  local on_line = opts.on_line
  local on_exit = opts.on_exit

  function opts.on_line(line)
    self.status = line

    if on_line then
      pcall(on_line, line)
    end

    vim.cmd("do User LazyRender")
  end

  function opts.on_exit(ok, output)
    self.output = output

    if not ok then
      self.error = output
    end

    if on_exit then
      pcall(on_exit, ok, output)
    end

    self:_done()
  end

  Process.spawn(cmd, opts)
end

function Task:start()
  self.running = true
  local ok, err = pcall(function()
    if self.type == "update" then
      self:update()
    elseif self.type == "install" then
      self:install()
    elseif self.type == "run" then
      self:run()
    elseif self.type == "clean" then
      self:clean()
    end
  end)

  if not ok then
    self.error = err or "failed"

    self:_done()
  end
end

function Task:update()
  if Util.file_exists(self.plugin.uri) then
    if vim.loop.fs_realpath(self.plugin.uri) ~= vim.loop.fs_realpath(self.plugin.dir) then
      vim.loop.fs_unlink(self.plugin.dir)
      vim.loop.fs_symlink(self.plugin.uri, self.plugin.dir, {
        dir = true,
      })
      vim.opt.runtimepath:append(self.plugin.uri)
    end

    self:_done()
  else
    local args = {
      "pull",
      "--recurse-submodules",
      "--update-shallow",
      "--progress",
    }
    local git = Util.git_info(self.plugin.dir)

    self:spawn("git", {
      args = args,
      cwd = self.plugin.dir,
      on_exit = function(ok)
        if ok then
          local git_new = Util.git_info(self.plugin.dir)
          self.plugin.dirty = not vim.deep_equal(git, git_new)
        end
      end,
    })
  end
end

return Task
