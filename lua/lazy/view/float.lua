local Config = require("lazy.core.config")
local Util = require("lazy.util")
local ViewConfig = require("lazy.view.config")

---@class LazyFloatOptions
---@field buf? number
---@field file? string
---@field margin? {top?:number, right?:number, bottom?:number, left?:number}
---@field size? {width:number, height:number}
---@field zindex? number
---@field style? "" | "minimal"
---@field border? "none" | "single" | "double" | "rounded" | "solid" | "shadow"
---@field title? string
---@field title_pos? "center" | "left" | "right"
---@field persistent? boolean
---@field ft? string
---@field noautocmd? boolean
---@field backdrop? float

---@class LazyFloat
---@field buf number
---@field win number
---@field opts LazyFloatOptions
---@field win_opts LazyWinOpts
---@field backdrop_buf number
---@field backdrop_win number
---@field id number
---@overload fun(opts?:LazyFloatOptions):LazyFloat
local M = {}

setmetatable(M, {
  __call = function(_, ...)
    return M.new(...)
  end,
})

local _id = 0
local function next_id()
  _id = _id + 1
  return _id
end

---@param opts? LazyFloatOptions
function M.new(opts)
  local self = setmetatable({}, { __index = M })
  return self:init(opts)
end

---@param opts? LazyFloatOptions
function M:init(opts)
  require("lazy.view.colors").setup()
  self.id = next_id()
  self.opts = vim.tbl_deep_extend("force", {
    size = Config.options.ui.size,
    style = "minimal",
    border = Config.options.ui.border or "none",
    backdrop = Config.options.ui.backdrop or 60,
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
    noautocmd = self.opts.noautocmd,
    title = self.opts.title,
    title_pos = self.opts.title and self.opts.title_pos or nil,
  }
  self:mount()
  self:on("VimEnter", function()
    vim.schedule(function()
      if not self:win_valid() then
        self:close()
      end
    end)
  end, { buffer = false })
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

  if self.opts.border ~= "none" then
    self.win_opts.row = self.win_opts.row - 1
    self.win_opts.col = self.win_opts.col - 1
  end

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
  if self:buf_valid() then
    -- keep existing buffer
    self.buf = self.buf
  elseif self.opts.file then
    self.buf = vim.fn.bufadd(self.opts.file)
    vim.bo[self.buf].readonly = true
    vim.bo[self.buf].swapfile = false
    vim.fn.bufload(self.buf)
    vim.bo[self.buf].modifiable = false
  elseif self.opts.buf then
    self.buf = self.opts.buf
  else
    self.buf = vim.api.nvim_create_buf(false, true)
  end

  local normal, has_bg
  if vim.fn.has("nvim-0.9.0") == 0 then
    normal = vim.api.nvim_get_hl_by_name("Normal", true)
    has_bg = normal and normal.background ~= nil
  else
    normal = vim.api.nvim_get_hl(0, { name = "Normal" })
    has_bg = normal and normal.bg ~= nil
  end

  if has_bg and self.opts.backdrop and self.opts.backdrop < 100 and vim.o.termguicolors then
    self.backdrop_buf = vim.api.nvim_create_buf(false, true)
    self.backdrop_win = vim.api.nvim_open_win(self.backdrop_buf, false, {
      relative = "editor",
      width = vim.o.columns,
      height = vim.o.lines,
      row = 0,
      col = 0,
      style = "minimal",
      focusable = false,
      zindex = self.opts.zindex - 1,
    })
    vim.api.nvim_set_hl(0, "LazyBackdrop", { bg = "#000000", default = true })
    Util.wo(self.backdrop_win, "winhighlight", "Normal:LazyBackdrop")
    Util.wo(self.backdrop_win, "winblend", self.opts.backdrop)
    vim.bo[self.backdrop_buf].buftype = "nofile"
    vim.bo[self.backdrop_buf].filetype = "lazy_backdrop"
  end

  self:layout()
  self.win = vim.api.nvim_open_win(self.buf, true, self.win_opts)
  self:on("WinClosed", function()
    self:close()
    self:augroup(true)
  end, { win = true })
  self:focus()
  self:on_key(ViewConfig.keys.close, self.close, "Close")
  self:on({ "BufDelete", "BufHidden" }, self.close)

  if vim.bo[self.buf].buftype == "" then
    vim.bo[self.buf].buftype = "nofile"
  end
  if vim.bo[self.buf].filetype == "" then
    vim.bo[self.buf].filetype = self.opts.ft or "lazy"
  end

  local function opts()
    vim.bo[self.buf].bufhidden = self.opts.persistent and "hide" or "wipe"
    Util.wo(self.win, "conceallevel", 3)
    Util.wo(self.win, "foldenable", false)
    Util.wo(self.win, "spell", false)
    Util.wo(self.win, "wrap", true)
    Util.wo(self.win, "winhighlight", "Normal:LazyNormal")
    Util.wo(self.win, "colorcolumn", "")
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

      if self.backdrop_win and vim.api.nvim_win_is_valid(self.backdrop_win) then
        vim.api.nvim_win_set_config(self.backdrop_win, {
          width = vim.o.columns,
          height = vim.o.lines,
        })
      end

      opts()
      vim.api.nvim_exec_autocmds("User", { pattern = "LazyFloatResized", modeline = false })
    end,
  })
end

---@param clear? boolean
function M:augroup(clear)
  return vim.api.nvim_create_augroup("trouble.window." .. self.id, { clear = clear == true })
end

---@param events string|string[]
---@param fn fun(self:LazyFloat, event:{buf:number}):boolean?
---@param opts? vim.api.keyset.create_autocmd | {buffer: false, win?:boolean}
function M:on(events, fn, opts)
  opts = opts or {}
  if opts.win then
    opts.pattern = self.win .. ""
    opts.win = nil
  elseif opts.buffer == nil then
    opts.buffer = self.buf
  elseif opts.buffer == false then
    opts.buffer = nil
  end
  if opts.pattern then
    opts.buffer = nil
  end
  local _self = Util.weak(self)
  opts.callback = function(e)
    local this = _self()
    if not this then
      -- delete the autocmd
      return true
    end
    return fn(this, e)
  end
  opts.group = self:augroup()
  vim.api.nvim_create_autocmd(events, opts)
end

---@param key string
---@param fn fun(self?)
---@param desc? string
---@param mode? string[]
function M:on_key(key, fn, desc, mode)
  vim.keymap.set(mode or "n", key, function()
    fn(self)
  end, {
    nowait = true,
    buffer = self.buf,
    desc = desc,
  })
end

---@param opts? {wipe:boolean}
function M:close(opts)
  self:augroup(true)
  local buf = self.buf
  local win = self.win
  local wipe = opts and opts.wipe
  if wipe == nil then
    wipe = not self.opts.persistent
  end

  self.win = nil
  if wipe then
    self.buf = nil
  end
  local backdrop_buf = self.backdrop_buf
  local backdrop_win = self.backdrop_win
  self.backdrop_buf = nil
  self.backdrop_win = nil

  vim.schedule(function()
    if backdrop_win and vim.api.nvim_win_is_valid(backdrop_win) then
      vim.api.nvim_win_close(backdrop_win, true)
    end
    if backdrop_buf and vim.api.nvim_buf_is_valid(backdrop_buf) then
      vim.api.nvim_buf_delete(backdrop_buf, { force = true })
    end
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if wipe and buf and vim.api.nvim_buf_is_valid(buf) then
      vim.diagnostic.reset(Config.ns, buf)
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    vim.cmd.redraw()
  end)
end

function M:win_valid()
  return self.win and vim.api.nvim_win_is_valid(self.win)
end

function M:buf_valid()
  return self.buf and vim.api.nvim_buf_is_valid(self.buf)
end

function M:hide()
  if self:win_valid() then
    self:close({ wipe = false })
  end
end

function M:toggle()
  if self:win_valid() then
    self:hide()
    return false
  else
    self:show()
    return true
  end
end

function M:show()
  if self:win_valid() then
    self:focus()
  elseif self:buf_valid() then
    self:mount()
  else
    error("LazyFloat: buffer closed")
  end
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
