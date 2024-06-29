---@diagnostic disable: inject-field
---@class LazyMinit:LazyConfig
---@field stdpath? string

local islist = vim.islist or vim.tbl_islist

---@alias MinitSetup (fun(spec:LazySpec, opts: LazyMinit):LazyMinit?) | (fun(opts: LazyMinit):LazyMinit?) | (fun(spec:LazySpec, opts: LazyMinit):LazyMinit?)

local M = {}

---@param opts LazyMinit
---@return LazySpec[]
local function get_spec(opts)
  local ret = opts.spec or {}
  return ret and type(ret) == "table" and islist(ret) and ret or { ret }
end

---@param defaults LazyMinit
---@param opts LazyMinit
function M.extend(defaults, opts)
  local spec = {}
  vim.list_extend(spec, get_spec(defaults))
  vim.list_extend(spec, get_spec(opts))
  return vim.tbl_deep_extend("force", defaults, opts, { spec = spec })
end

function M.setup(opts)
  opts = M.extend({
    change_detection = { enabled = false },
  }, opts)

  -- set stdpaths to use .tests
  local root = opts.stdpath or ".minit"
  root = vim.fn.fnamemodify(root, ":p")
  for _, name in ipairs({ "config", "data", "state", "cache" }) do
    vim.env[("XDG_%s_HOME"):format(name:upper())] = root .. "/" .. name
  end

  vim.o.loadplugins = true
  require("lazy").setup(opts)
  require("lazy").update():wait()
  if vim.bo.filetype == "lazy" then
    local errors = false
    for _, plugin in pairs(require("lazy.core.config").spec.plugins) do
      errors = errors or require("lazy.core.plugin").has_errors(plugin)
    end
    if not errors then
      vim.cmd.close()
    end
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

---@param opts LazyMinit
function M.busted(opts)
  opts = M.extend({
    spec = {
      "lunarmodules/busted",
      { dir = vim.fn.fnamemodify(".", ":p") },
    },
    rocks = { hererocks = true },
  }, opts)

  M.setup(opts)

  local Config = require("lazy.core.config")
  -- disable termnial output for the tests
  Config.options.headless = {}

  if not require("lazy.core.config").headless() then
    return vim.notify("busted can only run in headless mode. Please run with `nvim -l`", vim.log.levels.WARN)
  end
  -- run busted
  return pcall(require("busted.runner"), {
    standalone = false,
  }) or os.exit(1)
end

return M
