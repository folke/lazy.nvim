local Rocks = require("lazy.manage.rocks")

---@type table<string, LazyTaskDef>
local M = {}

local running = false
local has_rocks = nil ---@type boolean?

M.install = {
  skip = function(plugin)
    return plugin._.rocks_installed ~= false
  end,
  run = function(self)
    if has_rocks == nil then
      has_rocks = vim.fn.executable("luarocks") == 1
    end
    if not has_rocks then
      self.error = "This plugin has luarocks dependencies,\nbut the `luarocks` executable is not found.\nPlease install https://luarocks.org/ to continue.\n"
        .. "luarock deps: "
        .. vim.inspect(self.plugin.rocks)
      return
    end

    local started = false

    local function install()
      started = true
      self.status = "luarocks (install)"
      vim.api.nvim_exec_autocmds("User", { pattern = "LazyRender", modeline = false })
      self:spawn("luarocks", {
        args = Rocks.args("install", "--deps-mode", "one", "--deps-only", Rocks.get_rockspec(self.plugin)),
        on_exit = function(ok)
          running = false
          if ok then
            self.plugin._.rocks_installed = true
          end
        end,
      })
    end

    local timer = vim.uv.new_timer()
    timer:start(0, 100, function()
      if not running then
        running = true
        timer:stop()
        vim.schedule(install)
      end
    end)
    self.status = "luarocks (pending)"

    table.insert(self._running, function()
      return not started
    end)
  end,
}

return M
