---@param plugin LazyPlugin
---@param filter fun(task:LazyTask):boolean?
local function has_task(plugin, filter)
  if plugin._.tasks then
    for _, task in ipairs(plugin._.tasks) do
      if filter(task) then
        return true
      end
    end
  end
end

---@alias LazySection {title:string, filter:fun(plugin:LazyPlugin):boolean?}

---@type LazySection[]
return {
  {
    filter = function(plugin)
      return has_task(plugin, function(task)
        return task:has_errors()
      end)
    end,
    title = "Failed",
  },
  {
    filter = function(plugin)
      if plugin._.working then
        return true
      end
      return has_task(plugin, function(task)
        return task:running()
      end)
    end,
    title = "Working",
  },
  {
    filter = function(plugin)
      return plugin._.build
    end,
    title = "Build",
  },
  {
    filter = function(plugin)
      return has_task(plugin, function(task)
        if task.name ~= "log" then
          return
        end
        for _, line in ipairs(vim.split(task:output(), "\n")) do
          if line:find("^%w+ %S+!:") then
            return true
          end
        end
      end)
    end,
    title = "Breaking Changes",
  },
  {
    filter = function(plugin)
      return plugin._.updated and plugin._.updated.from ~= plugin._.updated.to
    end,
    title = "Updated",
  },
  {
    filter = function(plugin)
      return plugin._.cloned
    end,
    title = "Installed",
  },
  {
    ---@param plugin LazyPlugin
    filter = function(plugin)
      return plugin._.updates ~= nil
    end,
    title = "Updates",
  },
  {
    filter = function(plugin)
      return has_task(plugin, function(task)
        return task.name == "log" and vim.trim(task:output()) ~= ""
      end)
    end,
    title = "Log",
  },
  {
    filter = function(plugin)
      return plugin._.kind == "clean" and plugin._.installed
    end,
    title = "Clean",
  },
  {
    filter = function(plugin)
      return not plugin._.installed and plugin._.kind ~= "disabled"
    end,
    title = "Not Installed",
  },
  {
    filter = function(plugin)
      return plugin._.outdated
    end,
    title = "Outdated",
  },
  {
    filter = function(plugin)
      return plugin._.loaded ~= nil
    end,
    title = "Loaded",
  },
  {
    filter = function(plugin)
      return plugin._.installed
    end,
    title = "Not Loaded",
  },
  {
    filter = function(plugin)
      return plugin._.kind == "disabled"
    end,
    title = "Disabled",
  },
}
