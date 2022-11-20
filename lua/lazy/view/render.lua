local Config = require("lazy.config")
local Util = require("lazy.util")
local Manager = require("lazy.manager")
local Sections = require("lazy.view.sections")

local Text = require("lazy.view.text")

---@class Render:Text
---@field buf buffer
---@field win window
---@field padding number
---@field plugins LazyPlugin[]
---@field progress {total:number, done:number}
local M = setmetatable({}, { __index = Text })

function M.render_plugins(buf, win, padding)
  local self = setmetatable({}, { __index = M })
  self._lines = {}
  self.buf = buf
  self.win = win
  self.padding = padding
  Manager.check_clean()

  self.plugins = vim.tbl_values(Config.plugins)
  table.sort(self.plugins, function(a, b)
    return a.name < b.name
  end)

  self.progress = {
    total = 0,
    done = 0,
  }

  for _, plugin in ipairs(self.plugins) do
    if plugin.tasks then
      for _, task in ipairs(plugin.tasks) do
        self.progress.total = self.progress.total + 1
        if not task.running then
          self.progress.done = self.progress.done + 1
        end
      end
    end
  end

  self:title()

  for _, section in ipairs(Sections) do
    self:section(section)
  end

  self:trim()
  self:render(buf, padding)
  return self
end

function M:title()
  self:append("Lazy", "LazyH1")
  if self.progress.done < self.progress.total then
    self:append(" (" .. self.progress.done .. "/" .. self.progress.total .. ")", "LazyMuted"):nl()
    self:progressbar()
  else
    self:append(" (" .. #self.plugins .. ")", "LazyMuted"):nl()
  end
  self:nl()
end

function M:progressbar()
  local width = vim.api.nvim_win_get_width(self.win) - 2 * self.padding
  local done = math.floor((self.progress.done / self.progress.total) * width + 0.5)
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

---@param plugin LazyPlugin
function M:plugin(plugin)
  self:append("  - ", "LazySpecial"):append(plugin.name)
  if plugin.tasks then
    for _, task in ipairs(plugin.tasks) do
      if task.running then
        self:append(" [" .. task.type .. "] ", "Identifier")
        self:append(task.status, "LazyMuted")
      elseif task.error then
        local lines = vim.split(vim.trim(task.error), "\n")
        self:append(" [" .. task.type .. "] ", "Identifier")
        for l, line in ipairs(lines) do
          self:append(line, "LazyError")
          if l ~= #lines then
            self:nl()
          end
        end
      end
    end
  end
  self:nl()
  -- self:details(plugin)
end

---@param plugin LazyPlugin
function M:details(plugin)
  local git = Util.git_info(plugin.dir)
  if git then
    self:append(git.branch)
  end
  self:nl()
end

return M
