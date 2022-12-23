local Util = require("lazy.util")
local Render = require("lazy.view.render")
local Config = require("lazy.core.config")
local ViewConfig = require("lazy.view.config")
local Git = require("lazy.manage.git")

---@class LazyViewState
---@field mode string
---@field plugin? string
local default_state = {
  mode = "home",
  profile = {
    threshold = 0,
    sort_time_taken = false,
  },
}

---@class LazyView
---@field buf number
---@field win number
---@field render LazyRender
---@field state LazyViewState
---@field win_opts LazyViewWinOpts
local M = {}

---@type LazyView
M.view = nil

---@param mode? string
function M.show(mode)
  if Config.headless then
    return
  end

  M.view = M.view or M.create({ mode = mode })
  M.view:update(mode)
end

---@param opts? {mode?:string}
function M.create(opts)
  require("lazy.view.colors").setup()
  opts = opts or {}
  local self = setmetatable({}, { __index = M })

  self.state = vim.deepcopy(default_state)

  self:mount()

  self.render = Render.new(self)
  self.update = Util.throttle(Config.options.ui.throttle, self.update)

  self:on_key(ViewConfig.keys.close, self.close)

  self:on({ "BufDelete", "BufLeave", "BufHidden" }, self.close, { once = true })

  self:on("User LazyRender", function()
    if not (self.buf and vim.api.nvim_buf_is_valid(self.buf)) then
      return true
    end
    self:update()
  end)

  -- plugin details
  self:on_key(ViewConfig.keys.details, function()
    local plugin = self.render:get_plugin()
    if plugin then
      self.state.plugin = self.state.plugin ~= plugin.name and plugin.name or nil
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
        prompt = "Enter time threshold in ms, like 0.5",
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

  self:setup_patterns()
  self:setup_modes()
  return self
end

---@param events string|string[]
---@param fn fun(self?):boolean?
---@param opts? table
function M:on(events, fn, opts)
  if type(events) == "string" then
    events = { events }
  end
  for _, e in ipairs(events) do
    local event, pattern = e:match("(%w+) (%w+)")
    event = event or e
    vim.api.nvim_create_autocmd(
      event,
      vim.tbl_extend("force", {
        pattern = pattern,
        buffer = not pattern and self.buf or nil,
        callback = function()
          return fn(self)
        end,
      }, opts or {})
    )
  end
end

---@param key string
---@param fn fun(self?)
---@param desc? string
function M:on_key(key, fn, desc)
  vim.keymap.set("n", key, function()
    fn(self)
  end, {
    nowait = true,
    buffer = self.buf,
    desc = desc,
  })
end

---@param mode? string
function M:update(mode)
  if mode then
    self.state.mode = mode
  end
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

function M:close()
  local buf = self.buf
  local win = self.win
  self.win = nil
  self.buf = nil
  M.view = nil
  vim.diagnostic.reset(Config.ns, buf)
  vim.schedule(function()
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end)
end

function M:focus()
  vim.api.nvim_set_current_win(self.win)

  -- it seems that setting the current win doesn't work before VimEnter,
  -- so do that then
  if vim.v.vim_did_enter ~= 1 then
    vim.api.nvim_create_autocmd("VimEnter", {
      once = true,
      callback = function()
        if self.win and vim.api.nvim_win_is_valid(self.win) then
          pcall(vim.api.nvim_set_current_win, self.win)
        end
        return true
      end,
    })
  end
end

function M:mount()
  self.buf = vim.api.nvim_create_buf(false, false)

  local function size(max, value)
    return value > 1 and math.min(value, max) or math.floor(max * value)
  end
  ---@class LazyViewWinOpts
  self.win_opts = {
    relative = "editor",
    style = "minimal",
    border = Config.options.ui.border,
    width = size(vim.o.columns, Config.options.ui.size.width),
    height = size(vim.o.lines, Config.options.ui.size.height),
    noautocmd = true,
  }

  self.win_opts.row = (vim.o.lines - self.win_opts.height) / 2
  self.win_opts.col = (vim.o.columns - self.win_opts.width) / 2
  self.win = vim.api.nvim_open_win(self.buf, true, self.win_opts)
  self:focus()

  vim.bo[self.buf].buftype = "nofile"
  vim.bo[self.buf].filetype = "lazy"
  vim.bo[self.buf].bufhidden = "wipe"
  vim.wo[self.win].conceallevel = 3
  vim.wo[self.win].spell = false
  vim.wo[self.win].wrap = true
  vim.wo[self.win].winhighlight = "Normal:LazyNormal"
end

function M:setup_patterns()
  self:on_pattern(ViewConfig.keys.hover, {
    ["%f[a-z0-9](" .. string.rep("[a-z0-9]", 7) .. ")%f[^a-z0-9]"] = function(hash)
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
    ["|(%S-)|"] = vim.cmd.help, -- vim help links
    ["(https?://%S+)"] = function(url)
      Util.open(url)
    end,
  }, self.hover)
function M:hover()
  if self:diff({ browser = true }) then
    return
  end
  self:open_url("")
end

---@alias LazyDiff string|{from:string, to:string}

---@param opts? {commit?:string, browser:boolean}
function M:diff(opts)
  opts = opts or {}
  local plugin = self.render:get_plugin()
  if plugin then
    local diff
    if opts.commit then
      diff = opts.commit
    elseif plugin._.updated then
      diff = plugin._.updated
    else
      local info = assert(Git.info(plugin.dir))
      local target = assert(Git.get_target(plugin))
      diff = { from = info.commit, to = target.commit }
    end

    if not diff then
      return
    end

    if opts.browser then
      if plugin.url then
        local url = plugin.url:gsub("%.git$", "")
        if type(diff) == "string" then
          Util.open(url .. "/commit/" .. diff)
        else
          Util.open(url .. "/compare/" .. diff.from .. ".." .. diff.to)
        end
      else
        Util.error("No url for " .. plugin.name)
      end
    end
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
          return self:update("home")
        end
        Commands.cmd(name)
      end, m.desc)
    end
    if m.key_plugin then
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
