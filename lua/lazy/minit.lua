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
  opts = M.extend({ spec = { { dir = vim.fn.expand(".") } } }, opts)

  -- set stdpaths to use .tests
  local root = opts.stdpath or ".minit"
  root = vim.fn.fnamemodify(root, ":p")
  for _, name in ipairs({ "config", "data", "state", "cache" }) do
    vim.env[("XDG_%s_HOME"):format(name:upper())] = root .. "/" .. name
  end

  vim.o.loadplugins = true
  require("lazy").setup(opts)
end

---@param opts LazyMinit
function M.busted(opts)
  opts = M.extend({ spec = { "lunarmodules/busted" }, rocks = { hererocks = true } }, opts)

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
