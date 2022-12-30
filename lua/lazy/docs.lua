local Util = require("lazy.util")

local M = {}

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
    lines[l] = line:sub(width + 1)
  end
  return table.concat(lines, "\n")
end

---@param contents table<string, string>
function M.save(contents)
  local readme = Util.read_file("README.md")
  for tag, content in pairs(contents) do
    content = M.fix_indent(content)
    content = content:gsub("%%", "%%%%")
    content = vim.trim(content)
    local pattern = "(<%!%-%- " .. tag .. ":start %-%->).*(<%!%-%- " .. tag .. ":end %-%->)"
    if not readme:find(pattern) then
      error("tag " .. tag .. " not found")
    end
    if tag == "commands" or tag == "colors" or tag == "plugins" then
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

function M.commands()
  local commands = require("lazy.view.commands").commands
  local modes = require("lazy.view.config").commands
  modes.load.opts = true
  local lines = {
    { "Command", "Lua", "Description" },
    { "---", "---", "---", "---" },
  }
  Util.foreach(modes, function(name, mode)
    if commands[name] then
      if mode.plugins_required then
        lines[#lines + 1] = {
          ("`:Lazy %s {plugins}`"):format(name),
          ([[`require("lazy").%s(opts)`]]):format(name),
          mode.desc,
        }
      elseif mode.plugins then
        lines[#lines + 1] = {
          ("`:Lazy %s [plugins]`"):format(name),
          ([[`require("lazy").%s(opts?)`]]):format(name),
          mode.desc,
        }
      else
        lines[#lines + 1] = {
          ("`:Lazy %s`"):format(name),
          ([[`require("lazy").%s()`]]):format(name),
          mode.desc,
        }
      end
    end
  end)
  return M.table(lines)
end

---@param lines string[][]
function M.table(lines)
  ---@type string[]
  local ret = {}
  for _, line in ipairs(lines) do
    ret[#ret + 1] = "| " .. table.concat(line, " | ") .. " |"
  end
  return table.concat(ret, "\n")
end

function M.colors()
  local str = M.extract("lua/lazy/view/colors.lua", "\nM%.colors = ({.-\n})")
  ---@type table<string,string>
  local comments = {}
  for _, line in ipairs(vim.split(str, "\n")) do
    local group, desc = line:match("^  (%w+) = .* -- (.*)")
    if group then
      comments[group] = desc
    end
  end
  local lines = {
    { "Highlight Group", "Default Group", "Description" },
    { "---", "---", "---" },
  }
  Util.foreach(require("lazy.view.colors").colors, function(group, link)
    lines[#lines + 1] = { "**Lazy" .. group .. "**", "***" .. link .. "***", comments[group] or "" }
  end)
  return M.table(lines)
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
    stats = M.extract("lua/lazy/stats.lua", "\nM%._stats = ({.-\n})"),
    config = config,
    spec = Util.read_file("lua/lazy/example.lua"),
    commands = M.commands(),
    colors = M.colors(),
  })
  vim.cmd.checktime()
end

function M.plugins()
  local Config = require("lazy.core.config")
  local lines = { "## Plugins", "" }
  Util.foreach(Config.plugins, function(name, plugin)
    if plugin.url then
      lines[#lines + 1] = "- [" .. name .. "](" .. plugin.url:gsub("%.git$", "") .. ")"
    end
  end)
  M.save({ plugins = table.concat(lines, "\n") })
end

return M
