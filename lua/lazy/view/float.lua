local Config = require("lazy.core.config")
local ViewConfig = require("lazy.view.config")

---@class LazyViewOptions
---@field buf? number
---@field file? string
---@field margin? {top?:number, right?:number, bottom?:number, left?:number}
---@field win_opts LazyViewWinOpts
local defaults = {
  win_opts = {},
}

---@class LazyFloat
---@field buf number
---@field win number
---@field opts LazyViewOptions
---@overload fun(opts?:LazyViewOptions):LazyFloat
local M = {}

setmetatable(M, {
  __call = function(_, ...)
    return M.new(...)
  end,
})

---@param opts? LazyViewOptions
function M.new(opts)
  local self = setmetatable({}, { __index = M })
  return self:init(opts)
end

---@param opts? LazyViewOptions
function M:init(opts)
  self.opts = vim.tbl_deep_extend("force", defaults, opts or {})
  self:mount()
  self:on_key(ViewConfig.keys.close, self.close)
  self:on({ "BufDelete", "BufLeave", "BufHidden" }, self.close, { once = true })
  return self
end

function M:layout()
  local function size(max, value)
    return value > 1 and math.min(value, max) or math.floor(max * value)
  end
  self.opts.win_opts.width = size(vim.o.columns, Config.options.ui.size.width)
  self.opts.win_opts.height = size(vim.o.lines, Config.options.ui.size.height)
  self.opts.win_opts.row = math.floor((vim.o.lines - self.opts.win_opts.height) / 2)
  self.opts.win_opts.col = math.floor((vim.o.columns - self.opts.win_opts.width) / 2)

  if self.opts.margin then
    if self.opts.margin.top then
      self.opts.win_opts.height = self.opts.win_opts.height - self.opts.margin.top
      self.opts.win_opts.row = self.opts.win_opts.row + self.opts.margin.top
    end
    if self.opts.margin.right then
      self.opts.win_opts.width = self.opts.win_opts.width - self.opts.margin.right
    end
    if self.opts.margin.bottom then
      self.opts.win_opts.height = self.opts.win_opts.height - self.opts.margin.bottom
    end
    if self.opts.margin.left then
      self.opts.win_opts.width = self.opts.win_opts.width - self.opts.margin.left
      self.opts.win_opts.col = self.opts.win_opts.col + self.opts.margin.left
    end
  end
end

function M:mount()
  if self.opts.file then
    self.buf = vim.fn.bufadd(self.opts.file)
    vim.fn.bufload(self.buf)
    vim.bo[self.buf].modifiable = false
  elseif self.opts.buf then
    self.buf = self.opts.buf
  else
    self.buf = vim.api.nvim_create_buf(false, false)
  end

  ---@class LazyViewWinOpts
  local win_opts = {
    relative = "editor",
    style = "minimal",
    border = Config.options.ui.border,
    noautocmd = true,
    zindex = 50,
  }
  self.opts.win_opts = vim.tbl_extend("force", win_opts, self.opts.win_opts)
  if self.opts.win_opts.style == "" then
    self.opts.win_opts.style = nil
  end

  self:layout()
  self.win = vim.api.nvim_open_win(self.buf, true, self.opts.win_opts)
  self:focus()

  vim.bo[self.buf].buftype = "nofile"
  if vim.bo[self.buf].filetype == "" then
    vim.bo[self.buf].filetype = "lazy"
  end
  vim.bo[self.buf].bufhidden = "wipe"
  vim.wo[self.win].conceallevel = 3
  vim.wo[self.win].spell = false
  vim.wo[self.win].wrap = true
  vim.wo[self.win].winhighlight = "Normal:LazyNormal"

  vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
      if not self.win then
        return true
      end
      self:layout()
      local config = {}
      for _, key in ipairs({ "relative", "width", "height", "col", "row" }) do
        config[key] = self.opts.win_opts[key]
      end
      vim.api.nvim_win_set_config(self.win, config)
    end,
  })
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
        buffer = (not pattern) and self.buf or nil,
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

function M:close()
  local buf = self.buf
  local win = self.win
  self.win = nil
  self.buf = nil
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

return M
