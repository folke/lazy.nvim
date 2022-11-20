local Config = require("lazy.config")
local Task = require("lazy.task")
local Runner = require("lazy.runner")
local Util = require("lazy.util")

local M = {}

---@alias ManagerOpts {wait?: boolean, plugins?: LazyPlugin[], clear?: boolean, show?: boolean}

---@param operation TaskType
---@param opts? ManagerOpts
---@param filter? fun(plugin:LazyPlugin):boolean?
function M.run(operation, opts, filter)
	opts = opts or {}
	local plugins = opts.plugins or Config.plugins

	if opts.clear then
		M.clear()
	end

	if opts.show then
		require("lazy.view").show()
	end

	---@type Runner
	local runner = Runner.new()

	local on_done = function()
		vim.cmd([[do User LazyRender]])
	end

	-- install missing plugins
	for _, plugin in pairs(plugins) do
		if filter == nil or filter(plugin) then
			runner:add(Task.new(plugin, operation))
		end
	end

	if runner:is_empty() then
		return on_done()
	end

	vim.cmd([[do User LazyRender]])

	-- wait for install to finish
	runner:wait(function()
		-- check if we need to do any post-install hooks
		for _, plugin in ipairs(runner:plugins()) do
			if plugin.dirty and (plugin.opt == false or plugin.run) then
				runner:add(Task.new(plugin, "run"))
			end
			plugin.dirty = false
		end
		-- wait for post-install to finish
		runner:wait(on_done)
	end)

	-- auto show if there are tasks running
	if opts.show == nil then
		require("lazy.view").show()
	end

	if opts.wait then
		runner:wait()
	end
	return runner
end

---@param opts? ManagerOpts
function M.install(opts)
	---@param plugin LazyPlugin
	M.run("install", opts, function(plugin)
		return plugin.uri and not plugin.installed
	end)
end

---@param opts? ManagerOpts
function M.update(opts)
	---@param plugin LazyPlugin
	M.run("update", opts, function(plugin)
		return plugin.uri and plugin.installed
	end)
end

---@param opts? ManagerOpts
function M.clean(opts)
	M.check_clean()
	---@param plugin LazyPlugin
	M.run("clean", opts, function(plugin)
		return plugin.uri == nil and plugin.installed
	end)
end

function M.check_clean()
	---@type table<string,boolean>
	local packs = {}
	for _, plugin in pairs(Config.plugins) do
		packs[plugin.pack] = plugin.opt
	end

	for _, opt in ipairs({ "opt", "start" }) do
		local site = Config.options.package_path .. "/" .. opt
		if Util.file_exists(site) then
			for _, pack in ipairs(Util.scandir(site)) do
				if packs[pack.name] ~= (opt == "opt") then
					---@type LazyPlugin
					local plugin = {
						name = pack.name,
						pack = pack.name,
						dir = site .. "/" .. pack.name,
						opt = opt == "opt",
						installed = true,
					}
					Config.plugins[pack.name] = plugin
				end
			end
		end
	end
end

function M.clear()
	for pack, plugin in pairs(Config.plugins) do
		-- clear finished tasks
		if plugin.tasks then
			---@param task Task
			plugin.tasks = vim.tbl_filter(function(task)
				return task.running
			end, plugin.tasks)
		end
		-- clear cleaned plugins
		if plugin.uri == nil and not plugin.installed then
			Config.plugins[pack] = nil
		end
	end
end

return M
