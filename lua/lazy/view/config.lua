local M = {}

---@class LazyViewCommand
---@field id number
---@field plugins? boolean
---@field plugins_required? boolean
---@field button? boolean
---@field desc? string
---@field desc_plugin? string
---@field key? string
---@field key_plugin? string
---@field toggle? boolean

function M.get_commands()
  ---@type (LazyViewCommand|{name:string})[]
  local ret = {}
  for k, v in pairs(M.commands) do
    v.name = k
    ret[#ret + 1] = v
  end
  table.sort(ret, function(a, b)
    return a.id < b.id
  end)
  return ret
end

M.dimmed_commits = { "bot", "build", "ci", "chore", "doc", "style", "test" }

M.keys = {
  hover = "K",
  diff = "d",
  close = "q",
  details = "<cr>",
  profile_sort = "<C-s>",
  profile_filter = "<C-f>",
  abort = "<C-c>",
  next = "]]",
  prev = "[[",
}

---@type table<string,LazyViewCommand>
M.commands = {
  home = {
    button = true,
    desc = "Go back to plugin list",
    id = 1,
    key = "H",
  },
  install = {
    button = true,
    desc = "Install missing plugins",
    desc_plugin = "Install a plugin",
    id = 2,
    key = "I",
    key_plugin = "i",
    plugins = true,
  },
  update = {
    button = true,
    desc = "Update plugins. This will also update the lockfile",
    desc_plugin = "Update a plugin. This will also update the lockfile",
    id = 3,
    key = "U",
    key_plugin = "u",
    plugins = true,
  },
  sync = {
    button = true,
    desc = "Run install, clean and update",
    desc_plugin = "Run install, clean and update",
    id = 4,
    key = "S",
    plugins = true,
  },
  clean = {
    button = true,
    desc = "Clean plugins that are no longer needed",
    desc_plugin = "Delete a plugin. WARNING: this will delete the plugin even if it should be installed!",
    id = 5,
    key = "X",
    key_plugin = "x",
    plugins = true,
  },
  check = {
    button = true,
    desc = "Check for updates and show the log (git fetch)",
    desc_plugin = "Check for updates and show the log (git fetch)",
    id = 6,
    key = "C",
    key_plugin = "c",
    plugins = true,
  },
  log = {
    button = true,
    desc = "Show recent updates",
    desc_plugin = "Show recent updates",
    id = 7,
    key = "L",
    key_plugin = "gl",
    plugins = true,
  },
  restore = {
    button = true,
    desc = "Updates all plugins to the state in the lockfile. For a single plugin: restore it to the state in the lockfile or to a given commit under the cursor",
    desc_plugin = "Restore a plugin to the state in the lockfile or to a given commit under the cursor",
    id = 8,
    key = "R",
    key_plugin = "r",
    plugins = true,
  },
  profile = {
    button = true,
    desc = "Show detailed profiling",
    id = 9,
    key = "P",
    toggle = true,
  },
  debug = {
    button = true,
    desc = "Show debug information",
    id = 10,
    key = "D",
    toggle = true,
  },
  help = {
    button = true,
    desc = "Toggle this help page",
    id = 11,
    key = "?",
    toggle = true,
  },
  clear = {
    desc = "Clear finished tasks",
    id = 12,
  },
  load = {
    desc = "Load a plugin that has not been loaded yet. Similar to `:packadd`. Like `:Lazy load foo.nvim`. Use `:Lazy! load` to skip `cond` checks.",
    id = 13,
    plugins = true,
    plugins_required = true,
  },
  health = {
    desc = "Run `:checkhealth lazy`",
    id = 14,
  },
  build = {
    desc = "Rebuild a plugin",
    id = 15,
    plugins = true,
    plugins_required = true,
    key_plugin = "gb",
  },
  reload = {
    desc = "Reload a plugin (experimental!!)",
    plugins = true,
    plugins_required = true,
    id = 16,
  },
}

return M
