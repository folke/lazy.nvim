local Util = require("lazy.util")

local M = {}

function M.indent(str, indent)
  local lines = vim.split(str, "\n")
  for l, line in ipairs(lines) do
    lines[l] = (" "):rep(indent) .. line
  end
  return table.concat(lines, "\n")
end

function M.toc(md)
  local toc = {}
  local lines = vim.split(md, "\n")
  local toc_found = false
  for _, line in ipairs(lines) do
    local hash, title = line:match("^(#+)%s*(.*)")
    if hash then
      if toc_found then
        local anchor = string.gsub(title:lower(), "[^\32-\126]", "")
        anchor = string.gsub(anchor, " ", "-")
        toc[#toc + 1] = string.rep("  ", #hash - 1) .. "- [" .. title .. "](#" .. anchor .. ")"
      end
      if title:find("Table of Contents") then
        toc_found = true
      end
    end
  end
  return M.fix_indent(table.concat(toc, "\n"))
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
  local readme = Util.read_file("README.md")
  contents.toc = M.toc(readme)
  for tag, content in pairs(contents) do
    content = M.fix_indent(content)
    content = content:gsub("%%", "%%%%")
    content = vim.trim(content)
    local pattern = "(<%!%-%- " .. tag .. ":start %-%->).*(<%!%-%- " .. tag .. ":end %-%->)"
    if not readme:find(pattern) then
      error("tag " .. tag .. " not found")
    end
    if tag == "toc" then
      readme = readme:gsub(pattern, "%1\n\n" .. content .. "\n\n%2")
    else
      readme = readme:gsub(pattern, "%1\n\n```lua\n" .. content .. "\n```\n\n%2")
    end
  end

  Util.write_file("README.md", readme)
end

---@return string
function M.extract(file, pattern)
  local init = Util.read_file(file)
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
    spec = Util.read_file("lua/lazy/example.lua"),
  })
  vim.cmd.checktime()
end

M.update()

return M
