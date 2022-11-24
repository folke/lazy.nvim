local Process = require("lazy.process")
local Loader = require("lazy.core.loader")
local Util = require("lazy.util")

---@class LazyTask
---@field plugin LazyPlugin
---@field type TaskType
---@field running boolean
---@field opts TaskOptions
local Task = {}

---@alias TaskType "update"|"install"|"run"|"clean"|"log"|"docs"

---@class TaskOptions
local options = {
  log = {
    since = "7 days ago",
    ---@type string
    from = nil,
    ---@type string
    to = nil,
  },
}

---@param plugin LazyPlugin
---@param type TaskType
---@param opts? TaskOptions
function Task.new(plugin, type, opts)
  local self = setmetatable({}, {
    __index = Task,
  })
  self.opts = vim.tbl_deep_extend("force", {}, options, opts or {})
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

  self.plugin.installed = false
  self:_done()
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

  self:_done()
end

function Task:docs()
  local docs = self.plugin.dir .. "/doc/"
  if Util.file_exists(docs) then
    self.output = vim.api.nvim_cmd({ cmd = "helptags", args = { docs } }, { output = true })
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
    elseif self.type == "log" then
      self:log()
    elseif self.type == "docs" then
      self:docs()
    end
  end)

  if not ok then
    self.error = err or "failed"
    self:_done()
  end
end

function Task:log()
  if not Util.file_exists(self.plugin.dir .. "/.git") then
    self:_done()
    return
  end

  local args = {
    "log",
    "--pretty=format:%h %s (%cr)",
    "--abbrev-commit",
    "--decorate",
    "--date=short",
    "--color=never",
  }

  if self.opts.log.from then
    table.insert(args, self.opts.log.from .. ".." .. (self.opts.log.to or "HEAD"))
  else
    table.insert(args, "--since=" .. self.opts.log.since)
  end

  self:spawn("git", {
    args = args,
    cwd = self.plugin.dir,
  })
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
    local git = assert(Util.git_info(self.plugin.dir))

    self:spawn("git", {
      args = args,
      cwd = self.plugin.dir,
      on_exit = function(ok)
        if ok then
          local git_new = assert(Util.git_info(self.plugin.dir))
          self.plugin.updated = {
            from = git.hash,
            to = git_new.hash,
          }
          self.plugin.dirty = not vim.deep_equal(git, git_new)
        end
      end,
    })
  end
end

return Task
