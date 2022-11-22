local Util = require("lazy.core.util")
local Render = require("lazy.view.render")

local M = {}

function M.setup()
  require("lazy.view.commands").setup()
  require("lazy.view.colors").setup()
end

function M.show()
  require("lazy.view.colors").setup()

  if M._buf and vim.api.nvim_buf_is_valid(M._buf) then
    return
  end

  local buf = vim.api.nvim_create_buf(false, false)
  M._buf = buf
  local vpad = 6
  local hpad = 20
  local opts = {
    relative = "editor",
    style = "minimal",
    width = math.min(vim.o.columns - hpad * 2, 150),
    height = math.min(vim.o.lines - vpad * 2, 50),
  }
  opts.row = (vim.o.lines - opts.height) / 2
  opts.col = (vim.o.columns - opts.width) / 2
  local win = vim.api.nvim_open_win(buf, true, opts)

  vim.api.nvim_set_current_win(win)

  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.wo[win].conceallevel = 3
  vim.wo[win].spell = false
  vim.wo[win].wrap = true
  vim.wo[win].winhighlight = "Normal:LazyNormal"

  local function close()
    M._buf = nil

    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, {
        force = true,
      })
    end

    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end

  vim.keymap.set("n", "<ESC>", close, {
    nowait = true,
    buffer = buf,
  })

  vim.keymap.set("n", "q", close, {
    nowait = true,
    buffer = buf,
  })

  vim.api.nvim_create_autocmd({ "BufDelete", "BufLeave", "BufHidden" }, {
    once = true,
    buffer = buf,
    callback = close,
  })

  local render = Util.throttle(30, function()
    vim.bo[buf].modifiable = true
    Render.render_plugins(buf, win, 2)
    vim.bo[buf].modifiable = false
    vim.cmd.redraw()
  end)

  vim.api.nvim_create_autocmd("User", {
    pattern = "LazyRender",
    callback = function()
      if not vim.api.nvim_buf_is_valid(buf) then
        return true
      end

      render()
    end,
  })
  render()
end

return M
