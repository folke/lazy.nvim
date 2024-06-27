local Config = require("lazy.core.config")
local Util = require("lazy.util")

---@alias TextSegment {str: string, hl?:string|Extmark}
---@alias Extmark {hl_group?:string, col?:number, end_col?:number}

---@class Text
---@field _lines TextSegment[][]
---@field padding number
---@field wrap number
local Text = {}

function Text.new()
  local self = setmetatable({}, { __index = Text })
  self._lines = {}

  return self
end

---@param str string
---@param hl? string|Extmark
---@param opts? {indent?: number, prefix?: string, wrap?: boolean}
function Text:append(str, hl, opts)
  opts = opts or {}
  if #self._lines == 0 then
    self:nl()
  end

  local lines = vim.split(str, "\n")
  for l, line in ipairs(lines) do
    if opts.prefix then
      line = opts.prefix .. line
    end
    if opts.indent then
      line = string.rep(" ", opts.indent) .. line
    end
    if l > 1 then
      self:nl()
    end
    if
      Config.options.ui.wrap
      and opts.wrap
      and str ~= ""
      and self:col() > 0
      and self:col() + vim.fn.strwidth(line) + self.padding > self.wrap
    then
      self:nl()
    end
    table.insert(self._lines[#self._lines], {
      str = line,
      hl = hl,
    })
  end

  return self
end

function Text:nl()
  table.insert(self._lines, {})
  return self
end

function Text:render(buf)
  local lines = {}

  for _, line in ipairs(self._lines) do
    local str = (" "):rep(self.padding)
    local has_extmark = false

    for _, segment in ipairs(line) do
      str = str .. segment.str
      if type(segment.hl) == "table" then
        has_extmark = true
      end
    end

    if str:match("^%s*$") and not has_extmark then
      str = ""
    end
    table.insert(lines, str)
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, Config.ns, 0, -1)

  for l, line in ipairs(self._lines) do
    if lines[l] ~= "" then
      local col = self.padding

      for _, segment in ipairs(line) do
        local width = vim.fn.strlen(segment.str)

        local extmark = segment.hl
        if extmark then
          if type(extmark) == "string" then
            extmark = { hl_group = extmark, end_col = col + width }
          end
          ---@cast extmark Extmark

          local extmark_col = extmark.col or col
          extmark.col = nil
          local ok, err = pcall(vim.api.nvim_buf_set_extmark, buf, Config.ns, l - 1, extmark_col, extmark)
          if not ok then
            Util.error(
              "Failed to set extmark. Please report a bug with this info:\n"
                .. vim.inspect({ segment = segment, line = line, error = err })
            )
          end
        end

        col = col + width
      end
    end
  end
end

---@param patterns table<string,string>
function Text:highlight(patterns)
  local col = self.padding
  local last = self._lines[#self._lines]
  ---@type TextSegment?
  local text
  for s, segment in ipairs(last) do
    if s == #last then
      text = segment
      break
    end
    col = col + vim.fn.strlen(segment.str)
  end
  if text then
    for pattern, hl in pairs(patterns) do
      local from, to, match = text.str:find(pattern)
      while from do
        if match then
          from, to = text.str:find(match, from, true)
        end
        self:append("", {
          col = col + from - 1,
          end_col = col + to,
          hl_group = hl,
        })
        from, to = text.str:find(pattern, to + 1)
      end
    end
  end
end

function Text:trim()
  while #self._lines > 0 and #self._lines[#self._lines] == 0 do
    table.remove(self._lines)
  end
end

function Text:row()
  return #self._lines == 0 and 1 or #self._lines
end

function Text:col()
  if #self._lines == 0 then
    return 0
  end
  local width = 0
  for _, segment in ipairs(self._lines[#self._lines]) do
    width = width + vim.fn.strlen(segment.str)
  end
  return width
end

return Text
