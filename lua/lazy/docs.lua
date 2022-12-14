local M = {}

function M.read(file)
  local fd = assert(io.open(file, "r"))
  local data = fd:read("*a") ---@type string
  fd:close()
  return data
end

function M.indent(str, indent)
  local lines = vim.split(str, "\n")
  for l, line in ipairs(lines) do
    lines[l] = (" "):rep(indent) .. line
  end
  return table.concat(lines, "\n")
end

---@param str string
function M.fix_indent(str)
  local lines = vim.split(str, "\n")

  local width = 120
  for _, line in ipairs(lines) do
    width = math.min(width, #line:match("^%s*"))
  end

  for l, line in ipairs(lines) do
    lines[l] = line:sub(width)
  end
  return table.concat(lines, "\n")
end

---@param contents table<string, string>
function M.save(contents)
  local readme = M.read("README.md")
  for tag, content in pairs(contents) do
    content = M.fix_indent(content)
    content = content:gsub("%%", "%%%%")
    content = vim.trim(content)
    local pattern = "(<%!%-%- " .. tag .. "_start %-%->).*(<%!%-%- " .. tag .. "_end %-%->)"
    if not readme:find(pattern) then
      error("tag " .. tag .. " not found")
    end
    readme = readme:gsub(pattern, "%1\n\n```lua\n" .. content .. "\n```\n\n%2")
  end

  local fd = assert(io.open("README.md", "w+"))
  fd:write(readme)
  fd:close()
end

---@return string
function M.extract(file, pattern)
  local init = M.read(file)
  return assert(init:match(pattern))
end

function M.update()
  local cache_config = M.extract("lua/lazy/core/cache.lua", "\nM%.config = ({.-\n})")
  local config = M.extract("lua/lazy/core/config.lua", "\nM%.defaults = ({.-\n})")
  config = config:gsub(
    "\n%s*%-%-%-@type LazyCacheConfig.*cache = nil,",
    "\n" .. M.indent("cache = " .. cache_config .. ",", 4)
  )
  config = config:gsub("%s*debug = false.\n", "\n")
  M.save({
    bootstrap = M.extract("lua/lazy/init.lua", "function M%.bootstrap%(%)\n(.-)\nend"),
    config = config,
    spec = M.read("lua/lazy/example.lua"),
  })
  vim.cmd.checktime()
end

M.update()

return M
