local Config = require("lazy.core.config")
local Util = require("lazy.core.util")

--- This class is used to manage the fragments of a plugin spec.
--- It keeps track of the fragments and their relations to other fragments.
--- A fragment can be a dependency (dependencies) or a child (specs) of another fragment.
---@class LazyFragments
---@field fragments table<number, LazyFragment>
---@field frag_stack number[]
---@field dep_stack number[]
---@field dirty table<number, boolean>
---@field plugins table<LazyPlugin, number>
---@field spec LazySpecLoader
local M = {}

M._fid = 0

local function next_id()
  M._fid = M._fid + 1
  return M._fid
end

---@param spec LazySpecLoader
---@return LazyFragments
function M.new(spec)
  local self = setmetatable({}, { __index = M })
  self.fragments = {}
  self.frag_stack = {}
  self.dep_stack = {}
  self.spec = spec
  self.dirty = {}
  self.plugins = {}
  return self
end

---@param id number
function M:get(id)
  return self.fragments[id]
end

--- Remove a fragment and all its children.
--- This will also remove the fragment from its parent's children list.
---@param id number
function M:del(id)
  -- del fragment
  local fragment = self.fragments[id]
  if not fragment then
    return
  end

  self.dirty[id] = true

  -- remove from parent
  local pid = fragment.pid
  if pid then
    local parent = self.fragments[pid]
    if parent.frags then
      ---@param fid number
      parent.frags = Util.filter(function(fid)
        return fid ~= id
      end, parent.frags)
    end
    if parent.deps then
      ---@param fid number
      parent.deps = Util.filter(function(fid)
        return fid ~= id
      end, parent.deps)
    end
    self.dirty[pid] = true
  end

  -- remove children
  if fragment.frags then
    for _, fid in ipairs(fragment.frags) do
      self:del(fid)
    end
  end

  self.fragments[id] = nil
end

--- Add a fragment to the fragments list.
--- This also resolves its name, url, dir, dependencies and child specs.
---@param plugin LazyPluginSpec
function M:add(plugin)
  if self.plugins[plugin] then
    return self.fragments[self.plugins[plugin]]
  end

  local id = next_id()
  setmetatable(plugin, nil)

  self.plugins[plugin] = id

  local pid = self.frag_stack[#self.frag_stack]

  ---@type LazyFragment
  local fragment = {
    id = id,
    pid = pid,
    name = plugin.name,
    url = plugin.url,
    dir = plugin.dir,
    spec = plugin --[[@as LazyPlugin]],
  }

  -- short url / ref
  if plugin[1] then
    local slash = plugin[1]:find("/", 1, true)
    if slash then
      local prefix = plugin[1]:sub(1, 4)
      if prefix == "http" or prefix == "git@" then
        fragment.url = fragment.url or plugin[1]
      else
        fragment.name = fragment.name or plugin[1]:sub(slash + 1)
        fragment.url = fragment.url or Config.options.git.url_format:format(plugin[1])
      end
    else
      fragment.name = fragment.name or plugin[1]
    end
  end

  -- name
  fragment.name = fragment.name
    or fragment.url and self.spec.get_name(fragment.url)
    or fragment.dir and self.spec.get_name(fragment.dir)
  if not fragment.name or fragment.name == "" then
    return self.spec:error("Invalid plugin spec " .. vim.inspect(plugin))
  end

  if type(plugin.config) == "table" then
    self.spec:warn(
      "{" .. fragment.name .. "}: setting a table to `Plugin.config` is deprecated. Please use `Plugin.opts` instead"
    )
    ---@diagnostic disable-next-line: assign-type-mismatch
    plugin.opts = plugin.config
    plugin.config = nil
  end

  self.fragments[id] = fragment

  -- add to parent
  if pid then
    local parent = self.fragments[pid]
    parent.frags = parent.frags or {}
    table.insert(parent.frags, id)
  end

  -- add to parent's deps
  local did = self.dep_stack[#self.dep_stack]
  if did and did == pid then
    fragment.dep = true
    local parent = self.fragments[did]
    parent.deps = parent.deps or {}
    table.insert(parent.deps, id)
  end

  table.insert(self.frag_stack, id)
  -- dependencies
  if plugin.dependencies then
    table.insert(self.dep_stack, id)
    self.spec:normalize(plugin.dependencies)
    table.remove(self.dep_stack)
  end
  -- child specs
  if plugin.specs then
    self.spec:normalize(plugin.specs)
  end
  table.remove(self.frag_stack)

  return fragment
end

return M
