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

function M.update()
  M.themes()
  M.docs()
end

return M
