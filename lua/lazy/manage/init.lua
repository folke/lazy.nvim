local Config = require("lazy.core.config")
local Runner = require("lazy.manage.runner")
local Plugin = require("lazy.core.plugin")

local M = {}

---@class ManagerOpts
---@field wait? boolean
---@field clear? boolean
---@field interactive? boolean

---@param ropts RunnerOpts
---@param opts? ManagerOpts
function M.run(ropts, opts)
  opts = opts or {}
  if opts.interactive == nil then
    opts.interactive = Config.options.interactive
  end

  if opts.clear then
    M.clear()
  end

  if opts.interactive then
    vim.schedule(function()
      require("lazy.view").show()
    end)
  end

  ---@type Runner
  local runner = Runner.new(ropts)
  runner:start()

  vim.cmd([[do User LazyRender]])

  -- wait for post-install to finish
  runner:wait(function()
    vim.cmd([[do User LazyRender]])
  end)

  if opts.wait then
    runner:wait()
  end
  return runner
end

---@param opts? ManagerOpts
function M.install(opts)
  M.run({
    pipeline = {
      "fs.symlink",
      "git.clone",
      "git.checkout",
      "plugin.docs",
      "wait",
      "plugin.run",
    },
    plugins = function(plugin)
      return plugin.uri and not plugin._.installed
    end,
  }, opts)
end

---@param opts? ManagerOpts|{lockfile?:boolean}
function M.update(opts)
  opts = opts or {}
  M.run({
    pipeline = {
      "fs.symlink",
      "git.branch",
      "git.fetch",
      { "git.checkout", lockfile = opts.lockfile },
      "plugin.docs",
      "wait",
      "plugin.run",
      { "git.log", updated = true },
    },
    plugins = function(plugin)
      return plugin.uri and plugin._.installed
    end,
  }, opts):wait(function()
    require("lazy.manage.lock").update()
  end)
end

function M.check(opts)
  opts = opts or {}
  M.run({
    pipeline = {
      "git.fetch",
      "wait",
      { "git.log", check = true },
    },
    plugins = function(plugin)
      return plugin.uri and plugin._.installed
    end,
  }, opts)
end

---@param opts? ManagerOpts
function M.log(opts)
  M.run({
    pipeline = { "git.log" },
    plugins = function(plugin)
      return plugin.uri and plugin._.installed
    end,
  }, opts)
end

---@param opts? ManagerOpts
function M.clean(opts)
  Plugin.update_state(true)
  M.run({
    pipeline = { "fs.clean" },
    plugins = Config.to_clean,
  }, opts)
end

function M.clear()
  Plugin.update_state(true)
  for _, plugin in pairs(Config.plugins) do
    plugin._.updated = nil
    plugin._.cloned = nil
    plugin._.dirty = nil
    -- clear finished tasks
    if plugin._.tasks then
      ---@param task LazyTask
      plugin._.tasks = vim.tbl_filter(function(task)
        return task:is_running()
      end, plugin._.tasks)
    end
  end
  vim.cmd([[do User LazyRender]])
end

return M
