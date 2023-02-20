local Config = require("lazy.core.config")
local ViewConfig = require("lazy.view.config")

---@class LazyFloatOptions
---@field buf? number
---@field file? string
---@field margin? {top?:number, right?:number, bottom?:number, left?:number}
---@field size? {width:number, height:number}
---@field zindex? number
---@field style? "" | "minimal"
---@field border? "none" | "single" | "double" | "rounded" | "solid" | "shadow"

---@class LazyFloat
---@field buf number
---@field win number
---@field opts LazyFloatOptions
---@field win_opts LazyWinOpts
---@overload fun(opts?:LazyFloatOptions):LazyFloat
local M = {}

setmetatable(M, {
  __call = function(_, ...)
    return M.new(...)
  end,
})

---@param opts? LazyFloatOptions
function M.new(opts)
  local self = setmetatable({}, { __index = M })
  return self:init(opts)
end

---@param opts? LazyFloatOptions
function M:init(opts)
  self.opts = vim.tbl_deep_extend("force", {
    size = Config.options.ui.size,
    style = "minimal",
    border = Config.options.ui.border,
    zindex = 50,
  }, opts or {})

  ---@class LazyWinOpts
  ---@field width number
  ---@field height number
  ---@field row number
  ---@field col number
  self.win_opts = {
    relative = "editor",
    style = self.opts.style ~= "" and self.opts.style or nil,
    border = self.opts.border,
    zindex = self.opts.zindex,
    noautocmd = true,
  }
  self:mount()
  self:on_key(ViewConfig.keys.close, self.close)
  self:on({ "BufDelete", "BufHidden" }, self.close, { once = true })
  return self
end

function M:layout()
  local function size(max, value)
    return value > 1 and math.min(value, max) or math.floor(max * value)
  end
  self.win_opts.width = size(vim.o.columns, self.opts.size.width)
  self.win_opts.height = size(vim.o.lines, self.opts.size.height)
  self.win_opts.row = math.floor((vim.o.lines - self.win_opts.height) / 2)
  self.win_opts.col = math.floor((vim.o.columns - self.win_opts.width) / 2)

  if self.opts.margin then
    if self.opts.margin.top then
      self.win_opts.height = self.win_opts.height - self.opts.margin.top
      self.win_opts.row = self.win_opts.row + self.opts.margin.top
    end
    if self.opts.margin.right then
      self.win_opts.width = self.win_opts.width - self.opts.margin.right
    end
    if self.opts.margin.bottom then
      self.win_opts.height = self.win_opts.height - self.opts.margin.bottom
    end
    if self.opts.margin.left then
      self.win_opts.width = self.win_opts.width - self.opts.margin.left
      self.win_opts.col = self.win_opts.col + self.opts.margin.left
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

  self:layout()
  self.win = vim.api.nvim_open_win(self.buf, true, self.win_opts)
  self:focus()

  vim.bo[self.buf].buftype = "nofile"
  if vim.bo[self.buf].filetype == "" then
    vim.bo[self.buf].filetype = "lazy"
  end

  local function opts()
    vim.bo[self.buf].bufhidden = "wipe"
    vim.wo[self.win].conceallevel = 3
    vim.wo[self.win].foldenable = false
    vim.wo[self.win].spell = false
    vim.wo[self.win].wrap = true
    vim.wo[self.win].winhighlight = "Normal:LazyNormal"
    vim.wo[self.win].colorcolumn = ""
  end
  opts()

  vim.api.nvim_create_autocmd("VimResized", {
    callback = function()
      if not (self.win and vim.api.nvim_win_is_valid(self.win)) then
        return true
      end
      self:layout()
      local config = {}
      for _, key in ipairs({ "relative", "width", "height", "col", "row" }) do
        ---@diagnostic disable-next-line: no-unknown
        config[key] = self.win_opts[key]
      end
      config.style = self.opts.style ~= "" and self.opts.style or nil
      vim.api.nvim_win_set_config(self.win, config)
      opts()
      vim.api.nvim_exec_autocmds("User", { pattern = "LazyFloatResized", modeline = false })
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
  vim.schedule(function()
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if buf and vim.api.nvim_buf_is_valid(buf) then
      vim.diagnostic.reset(Config.ns, buf)
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
