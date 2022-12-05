local Util = require("lazy.util")
local Render = require("lazy.view.render")
local Config = require("lazy.core.config")

local M = {}

M.modes = {
  { name = "install", key = "I", desc = "Install missing plugins" },
  { name = "update", key = "U", desc = "Update all plugins. This will also update the lockfile" },
  { name = "sync", key = "S", desc = "Run install, clean and update" },
  { name = "clean", key = "X", desc = "Clean plugins that are no longer needed" },
  { name = "check", key = "C", desc = "Check for updates and show the log (git fetch)" },
  { name = "log", key = "L", desc = "Show recent updates for all plugins" },
  { name = "restore", key = "R", desc = "Updates all plugins to the state in the lockfile" },
  { name = "profile", key = "P", desc = "Show detailed profiling", toggle = true },
  { name = "debug", key = "D", desc = "Show debug information", toggle = true },
  { name = "help", key = "?", hide = true, desc = "Toggle this help page", toggle = true },

  { plugin = true, name = "update", key = "u", desc = "Update this plugin. This will also update the lockfile" },
  {
    plugin = true,
    name = "clean",
    key = "x",
    desc = "Delete this plugin. WARNING: this will delete the plugin even if it should be installed!",
  },
  { plugin = true, name = "check", key = "c", desc = "Check for updates for this plugin and show the log (git fetch)" },
  { plugin = true, name = "install", key = "i", desc = "Install this plugin" },
  { plugin = true, name = "log", key = "gl", desc = "Show recent updates for this plugin" },
  { plugin = true, name = "restore", key = "r", desc = "Restore this plugin to the state in the lockfile" },
}

---@type string?
M.mode = nil

function M.setup()
  require("lazy.view.commands").setup()
  require("lazy.view.colors").setup()
end

function M.show(mode)
  M.mode = mode or M.mode
  require("lazy.view.colors").setup()

  if M._buf and vim.api.nvim_buf_is_valid(M._buf) then
    -- vim.api.nvim_win_set_cursor(M._win, { 1, 0 })
    vim.cmd([[do User LazyRender]])
    return
  end

  local buf = vim.api.nvim_create_buf(false, false)
  M._buf = buf
  local vpad = 6
  local hpad = 20
  local opts = {
    relative = "editor",
    style = "minimal",
    border = Config.options.ui.border,
    width = math.min(vim.o.columns - hpad * 2, 200),
    height = math.min(vim.o.lines - vpad * 2, 70),
    noautocmd = true,
  }
  opts.row = (vim.o.lines - opts.height) / 2
  opts.col = (vim.o.columns - opts.width) / 2
  local win = vim.api.nvim_open_win(buf, true, opts)
  M._win = win

  vim.api.nvim_set_current_win(win)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.wo[win].conceallevel = 3
  vim.wo[win].spell = false
  vim.wo[win].wrap = true
  vim.wo[win].winhighlight = "Normal:LazyNormal"

  local function close()
    M._buf = nil
    vim.diagnostic.reset(Config.ns, buf)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
      end
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end)
  end

  vim.keymap.set("n", "q", close, {
    nowait = true,
    buffer = buf,
  })

  vim.api.nvim_create_autocmd({ "BufDelete", "BufLeave", "BufHidden" }, {
    once = true,
    buffer = buf,
    callback = close,
  })

  local render = Render.new(buf, win, 2)
  local update = Util.throttle(Config.options.ui.throttle, function()
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.bo[buf].modifiable = true
      render:update()
      vim.bo[buf].modifiable = false
      vim.cmd.redraw()
    end
  end)

  local function get_plugin()
    local pos = vim.api.nvim_win_get_cursor(win)
    return render:get_plugin(pos[1])
  end

  vim.keymap.set("n", "<cr>", function()
    local plugin = get_plugin()
    if plugin then
      if render._details == plugin.name then
        render._details = nil
      else
        render._details = plugin.name
      end
      update()
    end
  end, {
    nowait = true,
    buffer = buf,
  })

  local function open(path)
    local plugin = get_plugin()
    if plugin then
      local url = plugin.uri:gsub("%.git$", "")
      if Util.file_exists(url) then
        url = "https://github.com/" .. plugin[1]
      end
      Util.open(url .. path)
    end
  end

  M.keys(buf, {
    ["%s(" .. string.rep("[a-z0-9]", 7) .. ")%s"] = function(hash)
      open("/commit/" .. hash)
    end,
    ["%s(" .. string.rep("[a-z0-9]", 7) .. ")$"] = function(hash)
      open("/commit/" .. hash)
    end,
    ["^(" .. string.rep("[a-z0-9]", 7) .. ")%s"] = function(hash)
      open("/commit/" .. hash)
    end,
    ["#(%d+)"] = function(issue)
      open("/issues/" .. issue)
    end,
    ["README.md"] = function()
      local plugin = get_plugin()
      Util.open(plugin.dir .. "/README.md")
    end,
    ["|(%S-)|"] = vim.cmd.help, -- vim help links
    ["(https?://%S+)"] = function(url)
      Util.open(url)
    end,
  })

  for _, m in ipairs(M.modes) do
    vim.keymap.set("n", m.key, function()
      local Commands = require("lazy.view.commands")
      if m.plugin then
        local plugin = get_plugin()
        if plugin then
          Commands.cmd(m.name, { plugin })
        end
      else
        if M.mode == m.name and m.toggle then
          M.mode = nil
          return update()
        end
        Commands.cmd(m.name)
      end
    end, { buffer = buf })
  end

  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyRender",
    callback = function()
      if not vim.api.nvim_buf_is_valid(buf) then
        return true
      end
      update()
    end,
  })
  update()
end

---@param handlers table<string, fun(str:string)>
function M.keys(buf, handlers)
  local function map(lhs)
    vim.keymap.set("n", lhs, function()
      local line = vim.api.nvim_get_current_line()
      local pos = vim.api.nvim_win_get_cursor(0)
      local col = pos[2] + 1

      for pattern, handler in pairs(handlers) do
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
    end, { buffer = buf, silent = true })
  end

  map("K")
end

return M
