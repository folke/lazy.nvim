---@diagnostic disable: inject-field

local islist = vim.islist or vim.tbl_islist

local M = {}

---@param opts LazyConfig
---@return LazySpec[]
local function get_spec(opts)
  local ret = opts.spec or {}
  return ret and type(ret) == "table" and islist(ret) and ret or { ret }
end

---@param defaults LazyConfig
---@param opts LazyConfig
function M.extend(defaults, opts)
  local spec = {}
  vim.list_extend(spec, get_spec(defaults))
  vim.list_extend(spec, get_spec(opts))
  return vim.tbl_deep_extend("force", defaults, opts, { spec = spec })
end

---@param opts LazyConfig
function M.setup(opts)
  opts = M.extend({
    local_spec = false,
    change_detection = { enabled = false },
    dev = {
      patterns = vim.env.LAZY_DEV and vim.split(vim.env.LAZY_DEV, ",") or nil,
    },
  }, opts)

  local args = {}
  local is_busted = false
  local is_minitest = false
  local offline = vim.env.LAZY_OFFLINE == "1" or vim.env.LAZY_OFFLINE == "true"
  for _, a in ipairs(_G.arg) do
    if a == "--busted" then
      is_busted = true
    elseif a == "--minitest" then
      is_minitest = true
    elseif a == "--offline" then
      offline = true
    else
      table.insert(args, a)
    end
  end
  _G.arg = args

  if is_busted then
    opts = M.busted.setup(opts)
  elseif is_minitest then
    opts = M.minitest.setup(opts)
  end

  -- set stdpaths to use .tests
  if vim.env.LAZY_STDPATH then
    local root = vim.fn.fnamemodify(vim.env.LAZY_STDPATH, ":p")
    for _, name in ipairs({ "config", "data", "state", "cache" }) do
      vim.env[("XDG_%s_HOME"):format(name:upper())] = root .. "/" .. name
    end
  end
  vim.o.loadplugins = true
  require("lazy").setup(opts)
  if vim.g.colors_name == nil then
    vim.cmd("colorscheme habamax")
  end
  if not offline then
    require("lazy").update():wait()
  end
  if vim.bo.filetype == "lazy" then
    local errors = false
    for _, plugin in pairs(require("lazy.core.config").spec.plugins) do
      errors = errors or require("lazy.core.plugin").has_errors(plugin)
    end
    if not errors then
      vim.cmd.close()
    end
  end

  if is_busted then
    M.busted.run()
  elseif is_minitest then
    M.minitest.run()
  end
end

function M.repro(opts)
  opts = M.extend({
    spec = {
      {
        "folke/tokyonight.nvim",
        priority = 1000,
        lazy = false,
        config = function()
          require("tokyonight").setup({ style = "moon" })
          require("tokyonight").load()
        end,
      },
    },
    install = { colorscheme = { "tokyonight" } },
  }, opts)
  M.setup(opts)
end

M.minitest = {}

function M.minitest.run()
  local Config = require("lazy.core.config")
  -- disable termnial output for the tests
  Config.options.headless = {}

  if not require("lazy.core.config").headless() then
    return vim.notify("busted can only run in headless mode. Please run with `nvim -l`", vim.log.levels.WARN)
  end
  package.path = package.path .. ";" .. vim.uv.cwd() .. "/tests/?.lua"
  local Test = require("mini.test")
  local expect = Test.expect
  local _assert = assert
  local Assert = {
    __call = function(_, ...)
      return _assert(...)
    end,
    same = expect.equality,
    equal = expect.equality,
    are = {
      equal = expect.equality,
    },
    is_not = {
      same = expect.no_equality,
    },
    is_not_nil = function(a)
      return expect.no_equality(nil, a)
    end,
    is_true = function(a)
      return expect.equality(true, a)
    end,
    is_false = function(a)
      return expect.equality(false, a)
    end,
  }
  Assert.__index = Assert
  assert = setmetatable({}, Assert)
  assert = require("luassert")
  require("mini.test").run()
end

---@param opts LazyConfig
function M.minitest.setup(opts)
  return M.extend({
    spec = {
      "lunarmodules/luassert",
      {
        "echasnovski/mini.test",
        opts = {
          collect = {
            find_files = function()
              return #_G.arg > 0 and _G.arg or vim.fn.globpath("tests", "**/*_spec.lua", true, true)
            end,
          },
          -- script_path = "tests/minit.lua",
        },
      },
      { dir = vim.uv.cwd() },
    },
    rocks = { hererocks = true },
  }, opts)
end

M.busted = {}

function M.busted.run()
  local Config = require("lazy.core.config")
  -- disable termnial output for the tests
  Config.options.headless = {}

  if not require("lazy.core.config").headless() then
    return vim.notify("busted can only run in headless mode. Please run with `nvim -l`", vim.log.levels.WARN)
  end
  package.path = package.path .. ";" .. vim.uv.cwd() .. "/tests/?.lua"
  -- run busted
  return pcall(require("busted.runner"), {
    standalone = false,
  }) or os.exit(1)
end

---@param opts LazyConfig
function M.busted.setup(opts)
  local args = table.concat(_G.arg, " ")
  local json = args:find("--output[ =]json")

  return M.extend({
    spec = {
      "lunarmodules/busted",
      { dir = vim.uv.cwd() },
    },
    headless = {
      process = not json,
      log = not json,
      task = not json,
    },
    rocks = { hererocks = true },
  }, opts)
end

---@param opts LazyConfig
function M.busted.init(opts)
  opts = M.busted.setup(opts)
  M.setup(opts)
  M.busted.run()
end

setmetatable(M.busted, {
  __call = function(_, opts)
    M.busted.init(opts)
  end,
})

return M
