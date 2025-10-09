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

  local first = table.remove(lines, 1)

  local width = 120
  for _, line in ipairs(lines) do
    if not line:find("^%s*$") then
      width = math.min(width, #line:match("^%s*"))
    end
  end

  for l, line in ipairs(lines) do
    lines[l] = line:sub(width + 1)
  end
  table.insert(lines, 1, first)
  return table.concat(lines, "\n")
end

---@alias ReadmeBlock {content:string, lang?:string}
---@param contents table<string, ReadmeBlock|string>
---@param readme_file? string
function M.save(contents, readme_file)
  local readme = Util.read_file(readme_file or "README.md")
  for tag, block in pairs(contents) do
    if type(block) == "string" then
      block = { content = block, lang = "lua" }
    end
    ---@cast block ReadmeBlock
    local content = M.fix_indent(block.content)
    content = content:gsub("%%", "%%%%")
    content = vim.trim(content)
    local pattern = "(<%!%-%- " .. tag .. ":start %-%->).*(<%!%-%- " .. tag .. ":end %-%->)"
    if not readme:find(pattern) then
      error("tag " .. tag .. " not found")
    end
    if block.lang then
      readme = readme:gsub(pattern, "%1\n\n```" .. block.lang .. "\n" .. content .. "\n```\n\n%2")
    else
      readme = readme:gsub(pattern, "%1\n\n" .. content .. "\n\n%2")
    end
  end

  Util.write_file(readme_file or "README.md", readme)
  vim.cmd.checktime()
end

---@return string
function M.extract(file, pattern)
  local init = Util.read_file(file)
  local ret = assert(init:match(pattern)) --[[@as string]]
  local lines = vim.tbl_filter(function(line)
    return not line:find("^%s*%-%-%s*stylua%s*:%s*ignore%s*$")
  end, vim.split(ret, "\n"))
  return table.concat(lines, "\n")
end

---@return ReadmeBlock
function M.commands()
  local commands = require("lazy.view.commands").commands
  local modes = require("lazy.view.config").commands
  modes.load.opts = true
  local lines = {
    { "Command", "Lua", "Description" },
    { "---", "---", "---" },
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
  return { content = M.table(lines) }
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

---@param opts? {name?:string, path?:string, modname?:string}
---@return ReadmeBlock
function M.colors(opts)
  opts = vim.tbl_extend("force", {
    name = "Lazy",
    path = "lua/lazy/view/colors.lua",
    modname = "lazy.view.colors",
  }, opts or {})
  local str = M.extract(opts.path, "\nM%.colors = ({.-\n})")
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
  Util.foreach(require(opts.modname).colors, function(group, link)
    link = type(link) == "table" and "`" .. vim.inspect(link):gsub("%s+", " ") .. "`" or "***" .. link .. "***"
    lines[#lines + 1] = { "**" .. opts.name .. group .. "**", link, comments[group] or "" }
  end)
  return { content = M.table(lines) }
end

function M.update()
  local config = M.extract("lua/lazy/core/config.lua", "\nM%.defaults = ({.-\n})")
  config = config:gsub("%s*debug = false.\n", "\n")
  M.save({
    bootstrap = M.extract("lua/lazy/init.lua", "function M%.bootstrap%(%)\n(.-)\nend"),
    stats = M.extract("lua/lazy/stats.lua", "\nM%._stats = ({.-\n})"),
    config = config,
    spec = Util.read_file("lua/lazy/example.lua"),
    commands = M.commands(),
    colors = M.colors(),
  })
end

---@param plugins? LazyPlugin[]
---@return ReadmeBlock
function M.plugins(plugins)
  plugins = plugins or require("lazy.core.config").plugins
  ---@type string[]
  local lines = {}
  Util.foreach(plugins, function(name, plugin)
    if plugin.url then
      lines[#lines + 1] = "- [" .. name .. "](" .. plugin.url:gsub("%.git$", "") .. ")"
    end
  end)
  return { content = table.concat(lines, "\n") }
end

return M
