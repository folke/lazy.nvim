local Config = require("lazy.core.config")
local Plugin = require("lazy.core.plugin")
local Runner = require("lazy.manage.runner")

local M = {}

---@class ManagerOpts
---@field wait? boolean
---@field clear? boolean
---@field show? boolean
---@field mode? string
---@field plugins? (LazyPlugin|string)[]
---@field concurrency? number
---@field lockfile? boolean

---@param ropts RunnerOpts
---@param opts? ManagerOpts
function M.run(ropts, opts)
  opts = opts or {}

  local mode = opts.mode
  local event = mode and ("Lazy" .. mode:sub(1, 1):upper() .. mode:sub(2))

  if event then
    vim.api.nvim_exec_autocmds("User", { pattern = event .. "Pre", modeline = false })
  end

  if opts.plugins then
    ---@param plugin string|LazyPlugin
    opts.plugins = vim.tbl_map(function(plugin)
      return type(plugin) == "string" and Config.plugins[plugin] or plugin
    end, vim.tbl_values(opts.plugins))
    ropts.plugins = opts.plugins
  end

  ropts.concurrency = ropts.concurrency or opts.concurrency or Config.options.concurrency

  if opts.clear then
    M.clear(opts.plugins)
  end

  if opts.show ~= false then
    vim.schedule(function()
      require("lazy.view").show(opts.mode)
    end)
  end

  ---@type Runner
  local runner = Runner.new(ropts)
  runner:start()

  vim.api.nvim_exec_autocmds("User", { pattern = "LazyRender", modeline = false })

  -- wait for post-install to finish
  runner:wait(function()
    vim.api.nvim_exec_autocmds("User", { pattern = "LazyRender", modeline = false })
    Plugin.update_state()
    require("lazy.manage.checker").fast_check({ report = false })
    if event then
      vim.api.nvim_exec_autocmds("User", { pattern = event, modeline = false })
    end
  end)

  if opts.wait then
    runner:wait()
  end
  return runner
end

---@generic O: ManagerOpts
---@param opts? O
---@param defaults? ManagerOpts
---@return O
function M.opts(opts, defaults)
  return vim.tbl_deep_extend("force", { clear = true }, defaults or {}, opts or {})
end

---@param opts? ManagerOpts
function M.install(opts)
  opts = M.opts(opts, { mode = "install" })
  return M.run({
    pipeline = {
      "git.clone",
      { "git.checkout", lockfile = opts.lockfile },
      "plugin.docs",
      {
        "wait",
        ---@param runner Runner
        sync = function(runner)
          require("lazy.pkg").update()
          Plugin.load()
          runner:update()
        end,
      },
      "plugin.build",
    },
    plugins = function(plugin)
      return not (plugin._.installed and not plugin._.build)
    end,
  }, opts):wait(function()
    require("lazy.manage.lock").update()
    require("lazy.help").update()
  end)
end

---@param opts? ManagerOpts
function M.update(opts)
  opts = M.opts(opts, { mode = "update" })
  return M.run({
    pipeline = {
      "git.origin",
      "git.branch",
      "git.fetch",
      "git.status",
      { "git.checkout", lockfile = opts.lockfile },
      "plugin.docs",
      {
        "wait",
        ---@param runner Runner
        sync = function(runner)
          require("lazy.pkg").update()
          Plugin.load()
          runner:update()
        end,
      },
      "plugin.build",
      { "git.log", updated = true },
    },
    plugins = function(plugin)
      return plugin.url and plugin._.installed
    end,
  }, opts):wait(function()
    require("lazy.manage.lock").update()
    require("lazy.help").update()
  end)
end
--
---@param opts? ManagerOpts
function M.restore(opts)
  opts = M.opts(opts, { mode = "restore", lockfile = true })
  return M.update(opts)
end

---@param opts? ManagerOpts
function M.check(opts)
  opts = M.opts(opts, { mode = "check" })
  opts = opts or {}
  return M.run({
    pipeline = {
      { "git.origin", check = true },
      "git.fetch",
      "git.status",
      "wait",
      { "git.log", check = true },
    },
    plugins = function(plugin)
      return plugin.url and plugin._.installed
    end,
  }, opts)
end

---@param opts? ManagerOpts | {check?:boolean}
function M.log(opts)
  opts = M.opts(opts, { mode = "log" })
  return M.run({
    pipeline = {
      { "git.origin", check = true },
      { "git.log", check = opts.check },
    },
    plugins = function(plugin)
      return plugin.url and plugin._.installed
    end,
  }, opts)
end

---@param opts? ManagerOpts
function M.build(opts)
  opts = M.opts(opts, { mode = "build" })
  return M.run({
    pipeline = { { "plugin.build", force = true } },
    plugins = function()
      return false
    end,
  }, opts)
end

---@param opts? ManagerOpts
function M.sync(opts)
  opts = M.opts(opts)
  if opts.clear then
    M.clear()
    opts.clear = false
  end
  if opts.show ~= false then
    vim.schedule(function()
      require("lazy.view").show("sync")
    end)
    opts.show = false
  end

  vim.api.nvim_exec_autocmds("User", { pattern = "LazySyncPre", modeline = false })

  local clean_opts = vim.deepcopy(opts)
  clean_opts.plugins = nil
  local clean = M.clean(clean_opts)
  local install = M.install(opts)
  local update = M.update(opts)
  clean:wait(function()
    install:wait(function()
      update:wait(function()
        vim.api.nvim_exec_autocmds("User", { pattern = "LazySync", modeline = false })
      end)
    end)
  end)
end

---@param opts? ManagerOpts
function M.clean(opts)
  opts = M.opts(opts, { mode = "clean" })
  return M.run({
    pipeline = { "fs.clean" },
    plugins = Config.to_clean,
  }, opts):wait(function()
    require("lazy.manage.lock").update()
  end)
end

---@param plugins? LazyPlugin[]
function M.clear(plugins)
  for _, plugin in pairs(plugins or Config.plugins) do
    plugin._.updates = nil
    plugin._.updated = nil
    plugin._.cloned = nil
    plugin._.dirty = nil
    -- clear finished tasks
    if plugin._.tasks then
      ---@param task LazyTask
      plugin._.tasks = vim.tbl_filter(function(task)
        return task:running() or task:has_errors()
      end, plugin._.tasks)
    end
  end
  vim.api.nvim_exec_autocmds("User", { pattern = "LazyRender", modeline = false })
end

return M
