local Config = require("lazy.core.config")
local Diff = require("lazy.view.diff")
local Float = require("lazy.view.float")
local Git = require("lazy.manage.git")
local Render = require("lazy.view.render")
local Util = require("lazy.util")
local ViewConfig = require("lazy.view.config")

---@class LazyViewState
---@field mode string
---@field plugin? {name:string, kind?: LazyPluginKind}
local default_state = {
  mode = "home",
  profile = {
    threshold = 0,
    sort_time_taken = false,
  },
}

---@class LazyView: LazyFloat
---@field render LazyRender
---@field state LazyViewState
local M = {}

---@type LazyView
M.view = nil

function M.visible()
  return M.view and M.view.win and vim.api.nvim_win_is_valid(M.view.win)
end

---@param mode? string
function M.show(mode)
  if Config.headless() then
    return
  end

  M.view = M.visible() and M.view or M.create()
  if mode then
    M.view.state.mode = mode
  end
  M.view:update()
end

---@param plugin LazyPlugin
function M:is_selected(plugin)
  return vim.deep_equal(self.state.plugin, { name = plugin.name, kind = plugin._.kind })
end

function M.create()
  local self = setmetatable({}, { __index = setmetatable(M, { __index = Float }) })
  ---@cast self LazyView
  Float.init(self, {
    title = Config.options.ui.title,
    title_pos = Config.options.ui.title_pos,
    noautocmd = true,
  })

  if Config.options.ui.wrap then
    Util.wo(self.win, "wrap", true)
    Util.wo(self.win, "linebreak", true)
    Util.wo(self.win, "breakindent", true)
  else
    Util.wo(self.win, "wrap", false)
  end

  self.state = vim.deepcopy(default_state)

  self.render = Render.new(self)
  self.update = Util.throttle(Config.options.ui.throttle, self.update)

  self:on({ "User LazyRender", "User LazyFloatResized" }, function()
    if not (self.buf and vim.api.nvim_buf_is_valid(self.buf)) then
      return true
    end
    self:update()
  end)

  vim.keymap.set("n", ViewConfig.keys.abort, function()
    require("lazy.manage.process").abort()
    return ViewConfig.keys.abort
  end, { silent = true, buffer = self.buf, expr = true })

  -- plugin details
  self:on_key(ViewConfig.keys.details, function()
    local plugin = self.render:get_plugin()
    if plugin then
      local selected = {
        name = plugin.name,
        kind = plugin._.kind,
      }
      self.state.plugin = not vim.deep_equal(self.state.plugin, selected) and selected or nil
      self:update()
    end
  end)

  self:on_key(ViewConfig.keys.profile_sort, function()
    if self.state.mode == "profile" then
      self.state.profile.sort_time_taken = not self.state.profile.sort_time_taken
      self:update()
    end
  end)

  self:on_key(ViewConfig.keys.profile_filter, function()
    if self.state.mode == "profile" then
      vim.ui.input({
        prompt = "Enter time threshold in ms: ",
        default = tostring(self.state.profile.threshold),
      }, function(input)
        if not input then
          return
        end
        local num = input == "" and 0 or tonumber(input)
        if not num then
          Util.error("Please input a number")
        else
          self.state.profile.threshold = num
          self:update()
        end
      end)
    end
  end)

  for lhs, rhs in pairs(Config.options.ui.custom_keys) do
    if rhs then
      local handler = type(rhs) == "table" and rhs[1] or rhs
      self:on_key(lhs, function()
        local plugin = self.render:get_plugin()
        if plugin then
          handler(plugin)
        end
      end)
    end
  end

  self:setup_patterns()
  self:setup_modes()
  return self
end

function M:update()
  if self.buf and vim.api.nvim_buf_is_valid(self.buf) then
    vim.bo[self.buf].modifiable = true
    self.render:update()
    vim.bo[self.buf].modifiable = false
    vim.cmd.redraw()
  end
end

function M:open_url(path)
  local plugin = self.render:get_plugin()
  if plugin then
    if plugin.url then
      local url = plugin.url:gsub("%.git$", "")
      Util.open(url .. path)
    else
      Util.error("No url for " .. plugin.name)
    end
  end
end

function M:setup_patterns()
  local commit_pattern = "%f[%w](" .. string.rep("[a-f0-9]", 7) .. ")%f[%W]"
  self:on_pattern(ViewConfig.keys.hover, {
    [commit_pattern] = function(hash)
      self:diff({ commit = hash, browser = true })
    end,
    ["#(%d+)"] = function(issue)
      self:open_url("/issues/" .. issue)
    end,
    ["README.md"] = function()
      local plugin = self.render:get_plugin()
      if plugin then
        Util.open(plugin.dir .. "/README.md")
      end
    end,
    ["|(%S-)|"] = function(h)
      vim.cmd.help(h)
      self:close()
    end,
    ["(https?://%S+)"] = function(url)
      Util.open(url)
    end,
  }, self.hover)
  self:on_pattern(ViewConfig.keys.diff, {
    [commit_pattern] = function(hash)
      self:diff({ commit = hash })
    end,
  }, self.diff)
  self:on_pattern(ViewConfig.commands.restore.key_plugin, {
    [commit_pattern] = function(hash)
      self:restore({ commit = hash })
    end,
  }, self.restore)
end

---@param opts? {commit:string}
function M:restore(opts)
  opts = opts or {}
  local Lockfile = require("lazy.manage.lock")
  local Commands = require("lazy.view.commands")
  local plugin = self.render:get_plugin()
  if plugin then
    if opts.commit then
      Lockfile.get(plugin).commit = opts.commit
    end
    Commands.cmd("restore", { plugins = { plugin } })
  end
end

function M:hover()
  if self:diff({ browser = true }) then
    return
  end
  self:open_url("")
end

---@param opts? {commit?:string, browser:boolean}
function M:diff(opts)
  opts = opts or {}
  local plugin = self.render:get_plugin()
  if plugin then
    local diff
    if opts.commit then
      diff = { commit = opts.commit }
    elseif plugin._.updated then
      diff = vim.deepcopy(plugin._.updated)
    else
      local info = assert(Git.info(plugin.dir))
      local target = assert(Git.get_target(plugin))
      diff = { from = info.commit, to = target.commit }
    end

    if not diff then
      return
    end

    for k, v in pairs(diff) do
      diff[k] = v:sub(1, 7)
    end

    if opts.browser then
      Diff.handlers.browser(plugin, diff)
    else
      Diff.handlers[Config.options.diff.cmd](plugin, diff)
    end

    return true
  end
end

--- will create a key mapping that can be used on certain patterns
---@param key string
---@param patterns table<string, fun(str:string)>
---@param fallback? fun(self)
function M:on_pattern(key, patterns, fallback)
  self:on_key(key, function()
    local line = vim.api.nvim_get_current_line()
    local pos = vim.api.nvim_win_get_cursor(0)
    local col = pos[2] + 1

    for pattern, handler in pairs(patterns) do
      local from = 1
      local to, url
      while from do
        from, to, url = line:find(pattern, from)
        if from and col >= from and col <= to then
          return handler(url)
        end
        if from then
          from = to + 1
        end
      end
    end
    if fallback then
      fallback(self)
    end
  end)
end

function M:setup_modes()
  local Commands = require("lazy.view.commands")
  for name, m in pairs(ViewConfig.commands) do
    if m.key then
      self:on_key(m.key, function()
        if self.state.mode == name and m.toggle then
          self.state.mode = "home"
          return self:update()
        end
        Commands.cmd(name)
      end, m.desc)
    end
    if m.key_plugin and name ~= "restore" then
      self:on_key(m.key_plugin, function()
        local plugin = self.render:get_plugin()
        if plugin then
          Commands.cmd(name, { plugins = { plugin } })
        end
      end, m.desc_plugin)
    end
  end
end

return M
