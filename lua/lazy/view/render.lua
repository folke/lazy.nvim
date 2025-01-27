local Config = require("lazy.core.config")
local Git = require("lazy.manage.git")
local Handler = require("lazy.core.handler")
local Keys = require("lazy.core.handler.keys")
local Plugin = require("lazy.core.plugin")
local Sections = require("lazy.view.sections")
local Util = require("lazy.util")
local ViewConfig = require("lazy.view.config")

local Text = require("lazy.view.text")

---@alias LazyDiagnostic {row: number, severity: number, message:string}

---@class LazyRender:Text
---@field view LazyView
---@field plugins LazyPlugin[]
---@field progress {total:number, done:number}
---@field _diagnostics LazyDiagnostic[]
---@field locations {name:string, from: number, to: number, kind?: LazyPluginKind}[]
local M = {}

---@return LazyRender
---@param view LazyView
function M.new(view)
  ---@type LazyRender
  local self = setmetatable({}, { __index = setmetatable(M, { __index = Text }) })
  self.view = view
  self.padding = 2
  self.wrap = view.win_opts.width
  return self
end

function M:update()
  self._lines = {}
  self._diagnostics = {}
  self.locations = {}

  self.plugins = vim.tbl_values(Config.plugins)
  vim.list_extend(self.plugins, vim.tbl_values(Config.to_clean))
  vim.list_extend(self.plugins, vim.tbl_values(Config.spec.disabled))
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
        if not task:running() then
          self.progress.done = self.progress.done + 1
        end
      end
    end
  end

  self:title()

  local mode = self.view.state.mode
  if mode == "help" then
    self:help()
  elseif mode == "profile" then
    self:profile()
  elseif mode == "debug" then
    self:debug()
  else
    for _, section in ipairs(Sections) do
      self:section(section)
    end
  end

  self:trim()

  vim.bo[self.view.buf].modifiable = true
  local view = vim.api.nvim_win_call(self.view.win, vim.fn.winsaveview)

  self:render(self.view.buf)

  vim.api.nvim_win_call(self.view.win, function()
    vim.fn.winrestview(view)
  end)
  vim.bo[self.view.buf].modifiable = false

  vim.diagnostic.set(
    Config.ns,
    self.view.buf,
    ---@param diag LazyDiagnostic
    vim.tbl_map(function(diag)
      diag.col = 0
      diag.lnum = diag.row - 1
      return diag
    end, self._diagnostics),
    { signs = false, virtual_text = true, underline = false, virtual_lines = false }
  )
end

---@param row? number
---@return LazyPlugin?
function M:get_plugin(row)
  if not (self.view.win and vim.api.nvim_win_is_valid(self.view.win)) then
    return
  end
  row = row or vim.api.nvim_win_get_cursor(self.view.win)[1]
  for _, loc in ipairs(self.locations) do
    if row >= loc.from and row <= loc.to then
      if loc.kind == "clean" then
        for _, plugin in ipairs(Config.to_clean) do
          if plugin.name == loc.name then
            return plugin
          end
        end
      elseif loc.kind == "disabled" then
        return Config.spec.disabled[loc.name]
      else
        return Config.plugins[loc.name]
      end
    end
  end
end

---@param selected {name:string, kind?: LazyPluginKind}
function M:get_row(selected)
  for _, loc in ipairs(self.locations) do
    if loc.kind == selected.kind and loc.name == selected.name then
      return loc.from
    end
  end
end

function M:title()
  self:nl()
  local modes = vim.tbl_filter(function(c)
    return c.button
  end, ViewConfig.get_commands())

  if Config.options.ui.pills then
    self:nl()
    for c, mode in ipairs(modes) do
      local title = " " .. mode.name:sub(1, 1):upper() .. mode.name:sub(2) .. " (" .. mode.key .. ") "
      if mode.name == "home" then
        if self.view.state.mode == "home" then
          title = " lazy.nvim " .. Config.options.ui.icons.lazy
        end
      end

      if self.view.state.mode == mode.name then
        if mode.name == "home" then
          self:append(title, "LazyH1", { wrap = true })
        else
          self:append(title, "LazyButtonActive", { wrap = true })
          self:highlight({ ["%(.%)"] = "LazySpecial" })
        end
      else
        self:append(title, "LazyButton", { wrap = true })
        self:highlight({ ["%(.%)"] = "LazySpecial" })
      end
      if c == #modes then
        break
      end
      self:append(" ")
    end
    self:nl()
  end
  if self.progress.done < self.progress.total then
    self:progressbar()
  end
  self:nl()

  if self.view.state.mode ~= "help" and self.view.state.mode ~= "profile" and self.view.state.mode ~= "debug" then
    if self.progress.done < self.progress.total then
      self:append("Tasks: ", "LazyH2")
      self:append(self.progress.done .. "/" .. self.progress.total, "LazyComment")
    else
      self:append("Total: ", "LazyH2")
      self:append(#self.plugins .. " plugins", "LazyComment")
    end
    self:nl():nl()
  end
end

function M:help()
  self:append("Help", "LazyH2"):nl():nl()

  self:append("Use "):append(ViewConfig.keys.abort, "LazySpecial"):append(" to abort all running tasks."):nl():nl()

  self:append("You can press "):append("<CR>", "LazySpecial"):append(" on a plugin to show its details."):nl():nl()

  self:append("Most properties can be hovered with ")
  self:append("<K>", "LazySpecial")
  self:append(" to open links, help files, readmes and git commits."):nl()
  self
    :append("When hovering with ")
    :append("<K>", "LazySpecial")
    :append(" on a plugin anywhere else, a diff will be opened if there are updates")
    :nl()
  self:append("or the plugin was just updated. Otherwise the plugin webpage will open."):nl():nl()

  self:append("Use "):append("<d>", "LazySpecial"):append(" on a commit or plugin to open the diff view"):nl():nl()
  self
    :append("Use ")
    :append("<]]>", "LazySpecial")
    :append(" and ")
    :append("<[[>", "LazySpecial")
    :append(" to navigate between plugins")
    :nl()
    :nl()
  self:nl()

  self:append("Keyboard Shortcuts", "LazyH2"):nl()
  for _, mode in ipairs(ViewConfig.get_commands()) do
    if mode.key then
      local title = mode.name:sub(1, 1):upper() .. mode.name:sub(2)
      self:append("- ", "LazySpecial", { indent = 2 })
      self:append(title, "Title")
      if mode.key then
        self:append(" <" .. mode.key .. ">", "LazyProp")
      end
      self:append(" " .. (mode.desc or "")):nl()
    end
  end

  self:nl():append("Keyboard Shortcuts for Plugins", "LazyH2"):nl()
  for _, mode in ipairs(ViewConfig.get_commands()) do
    if mode.key_plugin then
      local title = mode.name:sub(1, 1):upper() .. mode.name:sub(2)
      self:append("- ", "LazySpecial", { indent = 2 })
      self:append(title, "Title")
      if mode.key_plugin then
        self:append(" <" .. mode.key_plugin .. ">", "LazyProp")
      end
      self:append(" " .. (mode.desc_plugin or mode.desc)):nl()
    end
  end
  for lhs, rhs in pairs(Config.options.ui.custom_keys) do
    if type(rhs) == "table" and rhs.desc then
      self:append("- ", "LazySpecial", { indent = 2 })
      self:append("Custom key ", "Title")
      self:append(lhs, "LazyProp")
      self:append(" " .. rhs.desc):nl()
    end
  end
end

function M:progressbar()
  local width = vim.api.nvim_win_get_width(self.view.win) - 2 * self.padding
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
  table.sort(section_plugins, function(a, b)
    return a.name:lower() < b.name:lower()
  end)
  if count > 0 then
    self:append(section.title, "LazyH2"):append(" (" .. count .. ")", "LazyComment"):nl()
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

---@param precision? number
function M:ms(nsec, precision)
  precision = precision or 2
  local e = math.pow(10, precision)
  return math.floor(nsec / 1e6 * e + 0.5) / e .. "ms"
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
    source = Util.norm(source)
    local plugin = Plugin.find(source)
    if plugin then
      reason.plugin = plugin.name
      reason.source = nil
    else
      local config = Util.norm(vim.fn.stdpath("config"))
      if source == config .. "/init.lua" then
        reason.source = "init.lua"
      else
        config = config .. "/lua"
        if source:find(config, 1, true) == 1 then
          reason.source = source:sub(#config + 2):gsub("/", "."):gsub("%.lua$", "")
        end
      end
    end
  end
  if reason.runtime then
    reason.runtime = Util.norm(reason.runtime)
    reason.runtime = reason.runtime:gsub(".*/([^/]+/plugin/.*)", "%1")
    reason.runtime = reason.runtime:gsub(".*/([^/]+/after/.*)", "%1")
    reason.runtime = reason.runtime:gsub(".*/([^/]+/ftdetect/.*)", "%1")
    reason.runtime = reason.runtime:gsub(".*/(runtime/.*)", "%1")
  end
  local time = reason.time and (" " .. self:ms(reason.time))
  if time and not opts.time_right then
    self:append(time, "Bold")
    self:append(" ")
  end
  -- self:append(" (", "Conceal")
  local first = true
  local keys = vim.tbl_keys(reason)
  table.sort(keys)
  if vim.tbl_contains(keys, "plugin") then
    keys = vim.tbl_filter(function(key)
      return key ~= "plugin"
    end, keys)
    table.insert(keys, "plugin")
  end
  for _, key in ipairs(keys) do
    local value = reason[key]
    local skip = type(key) == "number" or key == "time"
    if not skip then
      if first then
        first = false
      else
        self:append(" ")
      end
      local hl = "LazyReason" .. key:sub(1, 1):upper() .. key:sub(2)
      local icon = Config.options.ui.icons[key]
      if icon then
        icon = icon:gsub("%s*$", "")
        self:append(icon .. " ", hl)
        self:append(value, hl)
      else
        self:append(key .. " ", hl)
        self:append(value, hl)
      end
    end
  end
  if time and opts.time_right then
    self:append(time, "Bold")
  end
end

---@param plugin LazyPlugin
function M:diagnostics(plugin)
  local skip = false
  for _, task in ipairs(plugin._.tasks or {}) do
    if task:running() then
      self:diagnostic({
        severity = vim.diagnostic.severity.WARN,
        message = task.name .. (task:status() and (": " .. task:status()) or ""),
      })
      skip = true
    elseif task:has_errors() then
      self:diagnostic({
        message = task.name .. " failed",
        severity = vim.diagnostic.severity.ERROR,
      })
      skip = true
    elseif task:has_warnings() then
      self:diagnostic({
        message = task.name .. " warning",
        severity = vim.diagnostic.severity.WARN,
      })
      skip = true
    end
  end
  if skip then
    return
  end
  if plugin._.build then
    self:diagnostic({
      message = "needs build",
      severity = vim.diagnostic.severity.WARN,
    })
  elseif plugin._.updated then
    if plugin._.updated.from == plugin._.updated.to then
      self:diagnostic({
        message = "already up to date",
      })
    else
      local version = Git.info(plugin.dir, true).version
      if version then
        self:diagnostic({
          message = "updated to " .. tostring(version),
        })
      else
        self:diagnostic({
          message = "updated from " .. plugin._.updated.from:sub(1, 7) .. " to " .. plugin._.updated.to:sub(1, 7),
        })
      end
    end
  elseif plugin._.updates then
    local version = plugin._.updates.to.version
    if version then
      self:diagnostic({
        message = "version " .. tostring(version) .. " is available",
      })
    else
      self:diagnostic({
        message = "updates available",
      })
    end
  end
end

---@param plugin LazyPlugin
function M:plugin(plugin)
  local hl = plugin._.is_local and "LazyLocal" or "LazySpecial"
  if plugin._.loaded then
    self:append("  " .. Config.options.ui.icons.loaded .. " ", hl):append(plugin.name)
  elseif plugin._.cond == false then
    self:append("  " .. Config.options.ui.icons.not_loaded .. " ", "LazyNoCond"):append(plugin.name)
  else
    self:append("  " .. Config.options.ui.icons.not_loaded .. " ", hl):append(plugin.name)
  end
  local plugin_start = self:row()
  if plugin._.loaded then
    -- When the plugin is loaded, only show the loading reason
    self:reason(plugin._.loaded)
  else
    -- otherwise show all lazy handlers
    self:append(" ")
    self:handlers(plugin)
    for _, other in pairs(Config.plugins) do
      if vim.tbl_contains(other.dependencies or {}, plugin.name) then
        self:reason({ plugin = other.name })
        self:append(" ")
      end
    end
  end
  self:diagnostics(plugin)
  self:nl()

  if self.view:is_selected(plugin) then
    self:details(plugin)
  end
  self:tasks(plugin)
  self.locations[#self.locations + 1] =
    { name = plugin.name, from = plugin_start, to = self:row() - 1, kind = plugin._.kind }
end

---@param str string
---@param hl? string|Extmark
---@param opts? {indent?: number, prefix?: string, wrap?: boolean}
function M:markdown(str, hl, opts)
  local lines = vim.split(str, "\n")
  for _, line in ipairs(lines) do
    self:append(line, hl, opts):highlight({
      ["`.-`"] = "@markup.raw.markdown_inline",
      ["%*.-%*"] = "LazyItalic",
      ["%*%*.-%*%*"] = "LazyBold",
      ["^%s*-"] = "Special",
    })
    self:nl()
  end
end

---@param plugin LazyPlugin
function M:tasks(plugin)
  for _, task in ipairs(plugin._.tasks or {}) do
    if self.view:is_selected(plugin) then
      self:append(Config.options.ui.icons.task .. "[task] ", "Title", { indent = 4 }):append(task.name)
      self:append(" " .. math.floor((task:time()) * 100) / 100 .. "ms", "Bold")
      self:nl()
    end

    if not task:has_warnings() and task.name == "log" then
      self:log(task)
    else
      local hls = {
        [vim.log.levels.ERROR] = "LazyError",
        [vim.log.levels.WARN] = "LazyWarning",
        [vim.log.levels.INFO] = "LazyInfo",
      }
      for _, msg in ipairs(task:get_log()) do
        if task:has_warnings() or self.view:is_selected(plugin) then
          self:markdown(msg.msg, hls[msg.level] or "LazyTaskOutput", { indent = 6 })
        end
      end
    end
  end
end

---@param task LazyTask
function M:log(task)
  local log = vim.trim(task:output())
  if log ~= "" then
    local lines = vim.split(log, "\n")
    for _, line in ipairs(lines) do
      local ref, msg, time = line:match("^(%w+) (.*) (%(.*%))$")
      if msg then
        if msg:find("^%S+!:") then
          self:diagnostic({ message = "Breaking Changes", severity = vim.diagnostic.severity.WARN })
        end
        self:append(ref:sub(1, 7) .. " ", "LazyCommit", { indent = 6 })

        local dimmed = false
        for _, dim in ipairs(ViewConfig.dimmed_commits) do
          if msg:find("^" .. dim) then
            dimmed = true
          end
        end
        self:append(vim.trim(msg), dimmed and "LazyDimmed" or nil):highlight({
          ["#%d+"] = "LazyCommitIssue",
          ["^%S+:"] = dimmed and "Bold" or "LazyCommitType",
          ["^%S+(%(.*%))!?:"] = "LazyCommitScope",
          ["`.-`"] = "@markup.raw.markdown_inline",
          ["%*.-%*"] = "Italic",
          ["%*%*.-%*%*"] = "Bold",
        })
        self:append(" " .. time, "LazyComment")
        self:nl()
        -- else
        --   self:append(line, "LazyTaskOutput", { indent = 6 }):nl()
      end
    end
    self:nl()
  end
end

---@param plugin LazyPlugin
function M:details(plugin)
  ---@type string[][]
  local props = {}
  table.insert(props, { "dir", plugin.dir, "LazyDir" })
  if plugin.url then
    table.insert(props, { "url", (plugin.url:gsub("%.git$", "")), "LazyUrl" })
  end
  local git = Git.info(plugin.dir, true)
  if git then
    git.branch = git.branch or Git.get_branch(plugin)
    if git.version then
      table.insert(props, { "version", tostring(git.version) })
    end
    if git.tag then
      table.insert(props, { "tag", git.tag })
    end
    if git.branch then
      table.insert(props, { "branch", git.branch })
    end
    if git.commit then
      table.insert(props, { "commit", git.commit:sub(1, 7), "LazyCommit" })
    end
  end
  local rocks = require("lazy.pkg.rockspec").deps(plugin)
  if rocks then
    table.insert(props, { "rocks", vim.inspect(rocks) })
  end

  if Util.file_exists(plugin.dir .. "/README.md") then
    table.insert(props, { "readme", "README.md" })
  end
  Util.ls(plugin.dir .. "/doc", function(path, name)
    if name:sub(-3) == "txt" then
      local data = Util.read_file(path)
      local tag = data:match("%*(%S-)%*")
      if tag then
        table.insert(props, { "help", "|" .. tag .. "|" })
      end
    end
  end)

  for handler in pairs(plugin._.handlers or {}) do
    table.insert(props, {
      handler,
      function()
        self:handlers(plugin, handler)
      end,
    })
  end
  self:props(props, { indent = 6 })

  self:nl()
end

---@param plugin LazyPlugin
---@param types? LazyHandlerTypes[]|LazyHandlerTypes
function M:handlers(plugin, types)
  if not plugin._.handlers then
    return
  end
  types = type(types) == "string" and { types } or types
  types = types and types or vim.tbl_keys(Handler.types)
  for _, t in ipairs(types) do
    for id, value in pairs(plugin._.handlers[t] or {}) do
      value = t == "keys" and Keys.to_string(value) or id
      self:reason({ [t] = value })
      self:append(" ")
    end
  end
end

---@alias LazyProps {[1]:string, [2]:string|fun(), [3]?:string}[]
---@param props LazyProps
---@param opts? {indent: number}
function M:props(props, opts)
  opts = opts or {}
  local width = 0
  for _, prop in ipairs(props) do
    width = math.max(width, #prop[1])
  end
  for _, prop in ipairs(props) do
    self:append(prop[1] .. string.rep(" ", width - #prop[1] + 1), "LazyProp", { indent = opts.indent or 0 })
    if type(prop[2]) == "function" then
      prop[2]()
    else
      self:append(tostring(prop[2]), prop[3] or "LazyValue")
    end
    self:nl()
  end
end

function M:profile()
  local stats = require("lazy.stats").stats()
  local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
  self:append("Startuptime: ", "LazyH2"):append(ms .. "ms", "Number"):nl():nl()
  if stats.real_cputime then
    self:append("Based on the actual CPU time of the Neovim process till "):append("UIEnter", "LazySpecial")
    self:append("."):nl()
    self:append("This is more accurate than ")
    self:append("`nvim --startuptime`", "@markup.raw.markdown_inline")
    self:append(".")
  else
    self:append("An accurate startuptime based on the actual CPU time of the Neovim process is not available."):nl()
    self
      :append("Startuptime is instead based on a delta with a timestamp when lazy started till ")
      :append("UIEnter", "LazySpecial")
    self:append(".")
  end
  self:nl()

  local times = {}
  for event, time in pairs(require("lazy.stats").stats().times) do
    times[#times + 1] = { event, self:ms(time * 1e6), "Bold", time = time }
  end
  table.sort(times, function(a, b)
    return a.time < b.time
  end)
  for p, prop in ipairs(times) do
    if p > 1 then
      prop[2] = prop[2] .. " (+" .. self:ms((prop.time - times[p - 1].time) * 1e6) .. ")"
    end
  end
  self:props(times, { indent = 2 })

  self:nl()

  self:append("Profile", "LazyH2"):nl():nl()
  self
    :append("You can press ")
    :append(ViewConfig.keys.profile_sort, "LazySpecial")
    :append(" to change sorting between chronological order & time taken.")
    :nl()
  self
    :append("Press ")
    :append(ViewConfig.keys.profile_filter, "LazySpecial")
    :append(" to filter profiling entries that took more time than a given threshold")
    :nl()

  self:nl()

  ---@param a LazyProfile
  ---@param b LazyProfile
  local function sort(a, b)
    return a.time > b.time
  end

  ---@param entry LazyProfile
  local function get_children(entry)
    ---@type LazyProfile[]
    local children = entry

    if self.view.state.profile.sort_time_taken then
      children = {}
      for _, child in ipairs(entry) do
        children[#children + 1] = child
      end
      table.sort(children, sort)
    end
    return children
  end

  ---@param entry LazyProfile
  local function _profile(entry, depth)
    if entry.time / 1e6 < self.view.state.profile.threshold then
      return
    end
    local data = type(entry.data) == "string" and { source = entry.data } or entry.data
    data.time = entry.time
    local symbol = M.list_icon(depth)
    self:append(("  "):rep(depth)):append(symbol, "LazySpecial"):append(" ")
    self:reason(data, { time_right = true })
    self:nl()
    for _, child in ipairs(get_children(entry)) do
      _profile(child, depth + 1)
    end
  end

  for _, entry in ipairs(get_children(Util._profiles[1])) do
    _profile(entry, 1)
  end
end

function M.list_icon(depth)
  local symbols = Config.options.ui.icons.list
  return symbols[(depth - 1) % #symbols + 1]
end

function M:debug()
  self:append("Active Handlers", "LazyH2"):nl()
  self
    :append(
      "This shows only the lazy handlers that are still active. When a plugin loads, its handlers are removed",
      "LazyComment",
      { indent = 2 }
    )
    :nl()

  Util.foreach(require("lazy.core.handler").handlers, function(handler_type, handler)
    Util.foreach(handler.active, function(value, plugins)
      if not vim.tbl_isempty(plugins) then
        ---@type string[]
        plugins = vim.tbl_values(plugins)
        table.sort(plugins)
        self:append(Config.options.ui.icons.debug, "LazySpecial", { indent = 2 })
        if handler_type == "keys" then
          for k, v in pairs(Config.plugins[plugins[1]]._.handlers.keys) do
            if k == value then
              value = Keys.to_string(v)
              break
            end
          end
        end
        self:reason({ [handler_type] = value })
        for _, plugin in pairs(plugins) do
          self:append(" ")
          self:reason({ plugin = plugin })
        end
        self:nl()
      end
    end)
  end)
  self:nl()

  Util.foreach(require("lazy.core.cache")._inspect(), function(name, stats)
    self:append(name, "LazyH2"):nl()
    local props = {
      { "total", stats.total or 0, "Number" },
      { "time", self:ms(stats.time or 0, 3), "Bold" },
      { "avg time", self:ms((stats.time or 0) / (stats.total or 0), 3), "Bold" },
    }
    for k, v in pairs(stats) do
      if k ~= "total" and k ~= "time" then
        props[#props + 1] = { k, v, "Number" }
      end
    end
    self:props(props, { indent = 2 })
    self:nl()
  end)
end

return M
