local Docs = require("lazy.docs")
local Util = require("lazy.util")

local M = {}

---@param path string
local function dir(path)
  local plugin, extra = path:match("([^/]+)(.*)")
  return require("lazy.core.config").plugins[plugin].dir .. extra
end

M.extract = {
  ["configuration/index"] = {
    config = Docs.extract(dir("lazy.nvim/lua/lazy/core/config.lua"), "\nM%.defaults = ({.-\n})")
      :gsub("%s*debug = false.\n", "\n"),
  },
  ["configuration/highlights"] = {
    colors = Docs.colors({
      path = dir("lazy.nvim/lua/lazy/view/colors.lua"),
    }),
  },
  ["spec/examples"] = {
    examples = Util.read_file(dir("lazy.nvim/lua/lazy/example.lua")),
  },
  ["usage/index"] = {
    stats = Docs.extract(dir("lazy.nvim/lua/lazy/stats.lua"), "\nM%._stats = ({.-\n})"),
    commands = Docs.commands(),
  },
}

local function exec(cmd)
  return vim.system(vim.split(cmd, " "), { text = true }):wait()
end

function M.themes()
  exec("rm -rf src/themes")
  exec("mkdir -p src/themes")
  exec("cp -r .nvim/plugins/tokyonight.nvim/extras/prism src/themes/prism")
end

function M.installation()
  local install = Util.read_file("lua/tpl/install.lua")
  local install_multi = install:gsub(
    "spec = {}",
    [[spec = {
    -- import your plugins
    { import = "plugins" },
  }]]
  )
  local install_single = install:gsub(
    "spec = {}",
    [[spec = {
    -- add your plugins here
  }]]
  )
  return {
    install_single = {
      content = install_single,
      lang = 'lua title="~/.config/nvim/init.lua"',
    },
    install_multi = {
      content = install_multi,
      lang = 'lua title="~/.config/nvim/lua/config/lazy.lua"',
    },
  }
end

function M.docs()
  M.extract.installation = M.installation()
  for name, data in pairs(M.extract) do
    local md = "docs/" .. name .. ".md"
    if vim.uv.fs_stat(md .. "x") then
      md = md .. "x"
    end
    print("Building " .. md)
    Docs.save(data, md)
  end
end

function M._old()
  M.save({
    stats = M.extract("lua/lazy/stats.lua", "\nM%._stats = ({.-\n})"),
    commands = M.commands(),
  })
end

function M.readme()
  local mds = vim.fs.find(function(name, path)
    return name:match(".*%.mdx?$")
  end, { limit = math.huge, type = "file", path = "docs" })
  local sorters = {
    "intro",
    "installation",
    "spec",
    "packages",
    "configuration",
    "usage",
    "developers",
  }
  table.sort(mds, function(a, b)
    local aa = 0
    local bb = 0
    for i, name in ipairs(sorters) do
      if a:match(name) then
        aa = i
      end
      if b:match(name) then
        bb = i
      end
    end
    if aa == bb then
      if a:match("index") then
        return true
      elseif b:match("index") then
        return false
      end
      return a < b
    end
    return aa < bb
  end)
  local lines = {}
  for _, md in ipairs(mds) do
    table.insert(lines, ("```{.include}\n%s\n```"):format(md))
  end
  Util.write_file("README.md", vim.trim(table.concat(lines, "\n\n")))
end

function M.update()
  M.readme()
  M.themes()
  M.docs()
  vim.cmd.checktime()
end

return M
