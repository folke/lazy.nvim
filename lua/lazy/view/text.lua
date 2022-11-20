---@alias TextString {str: string, hl?:string, extmark?:table}
---@alias TextLine TextString[]

---@class Text
---@field _lines TextLine[]
local Text = {}

function Text.new()
  local self = setmetatable({}, {
    __index = Text,
  })
  self._lines = {}

  return self
end

---@param str string
---@param hl string|table
function Text:append(str, hl)
  if #self._lines == 0 then
    self:nl()
  end

  table.insert(self._lines[#self._lines], {
    str = str,
    hl = type(hl) == "string" and hl or nil,
    extmark = type(hl) == "table" and hl or nil,
  })

  return self
end

function Text:nl()
  table.insert(self._lines, {})
  return self
end

function Text:render(buf, padding)
  padding = padding or 0
  local lines = {}

  for _, line in ipairs(self._lines) do
    local str = (" "):rep(padding)

    for _, segment in ipairs(line) do
      str = str .. segment.str
    end

    table.insert(lines, str)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  for l, line in ipairs(self._lines) do
    local col = padding

    for _, segment in ipairs(line) do
      local width = vim.fn.strlen(segment.str)

      if segment.hl then
        vim.api.nvim_buf_set_extmark(buf, Config.ns, l - 1, col, {
          hl_group = segment.hl,
          end_col = col + width,
        })
      end

      if segment.extmark then
        vim.api.nvim_buf_set_extmark(buf, Config.ns, l - 1, col, segment.extmark)
      end

      col = col + width
    end
  end
end

function Text:trim()
  while #self._lines > 0 and #self._lines[1] == 0 do
    table.remove(self._lines, 1)
  end

  while #self._lines > 0 and #self._lines[#self._lines] == 0 do
    table.remove(self._lines)
  end
end

return Text
