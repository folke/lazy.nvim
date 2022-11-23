---@param plugin LazyPlugin
---@param filter fun(task:LazyTask):boolean?
local function has_task(plugin, filter)
  if plugin.tasks then
    for _, task in ipairs(plugin.tasks) do
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
        return task.error ~= nil
      end)
    end,
    title = "Failed",
  },
  {
    filter = function(plugin)
      return has_task(plugin, function(task)
        return task.running and task.type == "install"
      end)
    end,
    title = "Installing",
  },
  {
    filter = function(plugin)
      return has_task(plugin, function(task)
        return task.running and task.type == "update"
      end)
    end,
    title = "Updating",
  },
  {
    filter = function(plugin)
      return has_task(plugin, function(task)
        return task.running and task.type == "clean"
      end)
    end,
    title = "Cleaning",
  },
  {
    filter = function(plugin)
      return has_task(plugin, function(task)
        return task.running
      end)
    end,
    title = "Running",
  },
  {
    ---@param plugin LazyPlugin
    filter = function(plugin)
      return plugin.updated and plugin.updated.from ~= plugin.updated.to
    end,
    title = "Updated",
  },
  {
    filter = function(plugin)
      return has_task(plugin, function(task)
        return task.type == "log" and vim.trim(task.output) ~= ""
      end)
    end,
    title = "Log",
  },
  {
    filter = function(plugin)
      return plugin.installed and not plugin.uri
    end,
    title = "Clean",
  },
  {
    filter = function(plugin)
      return not plugin.installed and not plugin.uri
    end,
    title = "Cleaned",
  },
  {
    filter = function(plugin)
      return plugin.loaded
    end,
    title = "Loaded",
  },
  {
    filter = function(plugin)
      return plugin.installed
    end,
    title = "Installed",
  },
  {
    filter = function()
      return true
    end,
    title = "Not Installed",
  },
}
