local Config = require("lazy.core.config")
local Util = require("lazy.util")
local Sections = require("lazy.view.sections")
local Handler = require("lazy.core.handler")
local Git = require("lazy.manage.git")

local Text = require("lazy.view.text")

---@alias LazyDiagnostic {row: number, severity: number, message:string}

---@class Render:Text
---@field buf buffer
---@field win window
---@field plugins LazyPlugin[]
---@field progress {total:number, done:number}
---@field _diagnostics LazyDiagnostic[]
---@field plugin_range table<string, {from: number, to: number}>
---@field _details? string
local M = setmetatable({}, {
  __index = Text,
})

function M.new(buf, win, padding)
  local self = setmetatable({}, { __index = M })
  self.buf = buf
  self.win = win
  self.padding = padding or 0
  return self
end

function M:update()
  self._lines = {}
  self._diagnostics = {}
  self.plugin_range = {}

  self.plugins = vim.tbl_values(Config.plugins)
  vim.list_extend(self.plugins, vim.tbl_values(Config.to_clean))
  table.sort(self.plugins, function(a, b)
    return a.name < b.name
  end)

  self.progress = {
    total = 0,
    done = 0,
  }

  for _, plugin in ipairs(self.plugins) do
    if plugin._.tasks then
      for _, task in ipairs(plugin._.tasks) do
        self.progress.total = self.progress.total + 1
        if not task:is_running() then
          self.progress.done = self.progress.done + 1
        end
      end
    end
  end

  local mode = self:title()

  if mode == "help" then
    self:help()
  elseif mode == "profile" then
    self:profile()
  else
    for _, section in ipairs(Sections) do
      self:section(section)
    end
  end

  self:trim()
  self:render(self.buf)
  vim.diagnostic.set(
    Config.ns,
    self.buf,
    ---@param diag LazyDiagnostic
    vim.tbl_map(function(diag)
      diag.col = 0
      diag.lnum = diag.row - 1
      return diag
    end, self._diagnostics),
    { signs = false }
  )
end

---@param row number
---@return LazyPlugin?
function M:get_plugin(row)
  for name, range in pairs(self.plugin_range) do
    if row >= range.from and row <= range.to then
      return Config.plugins[name]
    end
  end
end

function M:title()
  self:append(" lazy.nvim ", "LazyH1"):center():nl()
  self:append("press "):append("<?>", "LazySpecial"):append(" for help"):center():nl()
  self:append("https://github.com/folke/lazy.nvim", "LazyMuted"):center():nl()

  local View = require("lazy.view")
  for _, mode in ipairs(View.modes) do
    if not mode.hide and not mode.plugin then
      local title = " " .. mode.name:sub(1, 1):upper() .. mode.name:sub(2) .. " (" .. mode.key .. ") "
      self:append(title, View.mode == mode.name and "LazyButtonActive" or "LazyButton"):append(" ")
    end
  end
  self:nl()
  if self.progress.done < self.progress.total then
    self:progressbar()
  end
  self:nl()

  if View.mode ~= "help" and View.mode ~= "profile" then
    if self.progress.done < self.progress.total then
      self:append("Tasks: ", "LazyH2")
      self:append(self.progress.done .. "/" .. self.progress.total, "LazyMuted")
    else
      self:append("Total: ", "LazyH2")
      self:append(#self.plugins .. " plugins", "LazyMuted")
    end
    self:nl():nl()
  end
  return View.mode
end

function M:help()
  local View = require("lazy.view")
  self:append("Help", "LazyH2"):nl():nl()

  self:append("Keyboard Shortcuts", "LazyH2"):nl()
  for _, mode in ipairs(View.modes) do
    local title = mode.name:sub(1, 1):upper() .. mode.name:sub(2)
    self:append("- ", "LazySpecial", { indent = 2 })
    self:append(title, "Title"):append(" <" .. mode.key .. "> ", "LazyKey")
    self:append(mode.desc or ""):nl()
  end
end

function M:progressbar()
  local width = vim.api.nvim_win_get_width(self.win) - 2 * self.padding
  local done = math.floor((self.progress.done / self.progress.total) * width + 0.5)
  if self.progress.done == self.progress.total then
    done = 0
  end
  self:append("", {
    virt_text_win_col = self.padding,
    virt_text = { { string.rep("─", done), "LazyProgressDone" } },
  })
  self:append("", {
    virt_text_win_col = done + self.padding,
    virt_text = { { string.rep("─", width - done), "LazyProgressTodo" } },
  })
end

---@param section LazySection
function M:section(section)
  ---@type LazyPlugin[]
  local section_plugins = {}
  ---@param plugin LazyPlugin
  self.plugins = vim.tbl_filter(function(plugin)
    if section.filter(plugin) then
      table.insert(section_plugins, plugin)
      return false
    end
    return true
  end, self.plugins)

  local count = #section_plugins
  if count > 0 then
    self:append(section.title, "LazyH2"):append(" (" .. count .. ")", "LazyMuted"):nl()
    for _, plugin in ipairs(section_plugins) do
      self:plugin(plugin)
    end
    self:nl()
  end
end

---@param diag LazyDiagnostic
function M:diagnostic(diag)
  diag.row = diag.row or self:row()
  diag.severity = diag.severity or vim.diagnostic.severity.INFO
  table.insert(self._diagnostics, diag)
end

---@param reason? {[string]:string, time:number}
---@param opts? {time_right?:boolean}
function M:reason(reason, opts)
  opts = opts or {}
  if not reason then
    return
  end
  reason = vim.deepcopy(reason)
  ---@type string?
  local source = reason.source
  if source then
    ---@type string?
    local modname = source:match("/lua/(.*)%.lua$")
    if modname then
      modname = modname:gsub("/", ".")
    end
    local name = source:match("/([^/]-)/lua")
    for _, other in pairs(Config.plugins) do
      if (modname and other.modname == modname) or (name and other.name == name) then
        reason.plugin = other.name
        reason.source = nil
        break
      end
    end
    if reason.source then
      reason.source = modname or reason.source
      if reason.source == "lua" then
        reason.source = Config.options.plugins
      end
    end
  end
  local time = " " .. math.floor((reason.time or 0) / 1e6 * 100) / 100 .. "ms"
  if not opts.time_right then
    self:append(time, "Bold")
  end
  self:append(" ")
  -- self:append(" (", "Conceal")
  local first = true
  for key, value in pairs(reason) do
    if type(key) == "number" then
    elseif key == "require" then
      -- self:append("require", "@function.builtin")
      -- self:append("(", "@punctuation.bracket")
      -- self:append('"' .. value .. '"', "@string")
      -- self:append(")", "@punctuation.bracket")
    elseif key ~= "time" then
      if first then
        first = false
      else
        self:append(" ")
      end
      if key == "event" then
        value = value:match("User (.*)") or value
      end
      local hl = "LazyLoader" .. key:sub(1, 1):upper() .. key:sub(2)
      local icon = Config.options.ui.icons[key]
      if icon then
        self:append(icon .. " ", hl)
        self:append(value, hl)
      else
        self:append(key .. " ", "@field")
        self:append(value, hl)
      end
    end
  end
  if opts.time_right then
    self:append(time, "Bold")
  end
  -- self:append(")", "Conceal")
end

---@param plugin LazyPlugin
function M:diagnostics(plugin)
  if plugin._.updated then
    if plugin._.updated.from == plugin._.updated.to then
      self:diagnostic({
        message = "already up to date",
      })
    else
      self:diagnostic({
        message = "updated from " .. plugin._.updated.from:sub(1, 7) .. " to " .. plugin._.updated.to:sub(1, 7),
      })
    end
  end
  for _, task in ipairs(plugin._.tasks or {}) do
    if task:is_running() then
      self:diagnostic({
        severity = vim.diagnostic.severity.WARN,
        message = task.name .. (task.status == "" and "" or (": " .. task.status)),
      })
    elseif task.error then
      self:diagnostic({
        message = task.name .. " failed",
        severity = vim.diagnostic.severity.ERROR,
      })
    end
  end
end

---@param plugin LazyPlugin
function M:plugin(plugin)
  if plugin._.loaded then
    self:append("  ● ", "LazySpecial"):append(plugin.name)
  else
    self:append("  ○ ", "LazySpecial"):append(plugin.name)
  end
  local plugin_start = self:row()
  if plugin._.loaded then
    self:reason(plugin._.loaded)
  end
  self:diagnostics(plugin)
  self:nl()

  if self._details == plugin.name then
    self:details(plugin)
  end
  self:tasks(plugin)
  self.plugin_range[plugin.name] = { from = plugin_start, to = self:row() - 1 }
end

---@param plugin LazyPlugin
function M:tasks(plugin)
  for _, task in ipairs(plugin._.tasks or {}) do
    if self._details == plugin.name then
      self:append("✔ [task] ", "Title", { indent = 4 }):append(task.name)
      self:append(" " .. math.floor((task:time()) * 100) / 100 .. "ms", "Bold")
      self:nl()
    end
    if task.name == "log" and not task.error then
      self:log(task)
    elseif task.error or self._details == plugin.name then
      if task.error then
        self:append(vim.trim(task.error), "LazyError", { indent = 4, prefix = "│ " })
        self:nl()
      end
      if task.output ~= "" and task.output ~= task.error then
        self:append(vim.trim(task.output), "MsgArea", { indent = 4, prefix = "│ " })
        self:nl()
      end
    end
  end
end

---@param task LazyTask
function M:log(task)
  local log = vim.trim(task.output)
  if log ~= "" then
    local lines = vim.split(log, "\n")
    for _, line in ipairs(lines) do
      local ref, msg, time = line:match("^(%w+) (.*) (%(.*%))$")
      if msg:find("^%S+!:") then
        self:diagnostic({ message = "Breaking Changes", severity = vim.diagnostic.severity.WARN })
      end
      self:append(ref .. " ", "LazyCommit", { indent = 6 })
      self:append(vim.trim(msg)):highlight({
        ["#%d+"] = "Number",
        ["^%S+:"] = "Title",
        ["^%S+(%(.*%)):"] = "Italic",
        ["`.-`"] = "@text.literal.markdown_inline",
      })
      -- string.gsub
      self:append(" " .. time, "Comment")
      self:nl()
    end
    self:nl()
  end
end

---@param plugin LazyPlugin
function M:details(plugin)
  ---@type string[][]
  local props = {}
  table.insert(props, { "uri", (plugin.uri:gsub("%.git$", "")), "@text.reference" })
  local git = Git.info(plugin.dir, true)
  if git then
    if git.version then
      table.insert(props, { "version", tostring(git.version) })
    end
    if git.tag then
      table.insert(props, { "tag", git.tag })
    end
    if git.branch then
      table.insert(props, { "branch", git.branch })
    end
    table.insert(props, { "commit", git.commit:sub(1, 7), "LazyCommit" })
  end
  if Util.file_exists(plugin.dir .. "/README.md") then
    table.insert(props, { "readme", "README.md" })
  end

  for handler in pairs(Handler.handlers) do
    if plugin[handler] then
      table.insert(props, {
        handler,
        type(plugin[handler]) == "string" and plugin[handler] or table.concat(plugin[handler], ", "),
        "@string",
      })
    end
  end

  local width = 0
  for _, prop in ipairs(props) do
    width = math.max(width, #prop[1])
  end
  for _, prop in ipairs(props) do
    self:append(prop[1] .. string.rep(" ", width - #prop[1] + 1), "LazyKey", { indent = 6 })
    self:append(prop[2], prop[3] or "LazyValue")
    self:nl()
  end
  self:nl()
end

function M:profile()
  self:append("Profile", "LazyH2"):nl():nl()
  local symbols = {
    "●",
    "➜",
    "★",
    "‒",
  }

  ---@param entry LazyProfile
  local function _profile(entry, depth)
    local data = type(entry.data) == "string" and { source = entry.data } or entry.data
    data.time = entry.time
    local symbol = symbols[depth] or symbols[#symbols]
    self:append(("  "):rep(depth)):append(" " .. symbol, "LazySpecial")
    self:reason(data, { time_right = true })
    self:nl()

    for _, child in ipairs(entry) do
      _profile(child, depth + 1)
    end
  end

  for _, entry in ipairs(Util._profiles[1]) do
    _profile(entry, 1)
  end
end

return M
