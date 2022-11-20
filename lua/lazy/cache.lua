local cache_file = vim.fn.stdpath("cache") .. "/lazy/cache.mpack"
vim.fn.mkdir(vim.fn.fnamemodify(cache_file, ":p:h"), "p")

local M = {}
---@alias CacheEntry {hash:string, chunk:string, used:boolean}

---@type table<string, CacheEntry>
M.cache = {}
M.dirty = false
M.did_setup = false

function M.hash(modpath)
	local stat = vim.loop.fs_stat(modpath)
	if stat then
		return stat.mtime.sec .. stat.mtime.nsec .. stat.size
	end
	error("Could not hash " .. modpath)
end

function M.load_cache()
	local f = io.open(cache_file, "rb")
	if f then
		M.cache = vim.mpack.decode(f:read("*a")) or {}
		f:close()
	end
end

function M.save_cache()
	if M.dirty then
		for key, entry in pairs(M.cache) do
			if not entry.used then
				M.cache[key] = nil
			end
			entry.used = nil
		end
		local f = assert(io.open(cache_file, "wb"))
		f:write(vim.mpack.encode(M.cache))
		f:close()
	end
end

function M.setup()
	M.load_cache()
	vim.api.nvim_create_autocmd("VimLeave", {
		callback = function()
			M.save_cache()
		end,
	})
end

function M.load(modpath, modname)
	if not M.did_setup then
		M.setup()
		M.did_setup = true
	end
	if type(package.loaded[modname]) ~= "table" then
		---@type fun()?, string?
		local chunk, err
		local entry = M.cache[modname]

		if entry and M.hash(modpath) == entry.hash then
			entry.used = true
			chunk, err = loadstring(entry.chunk, "@" .. modpath)
		end

		-- not cached, or failed to load chunk
		if not chunk then
			vim.schedule(function()
				vim.notify("not cached")
			end)
			chunk, err = loadfile(modpath)
			if chunk then
				M.cache[modname] = { hash = M.hash(modpath), chunk = string.dump(chunk, true), used = true }
				M.dirty = true
			end
		end

		if not chunk then
			error(err)
		end
		---@diagnostic disable-next-line: no-unknown
		package.loaded[modname] = chunk()
	end
	return package.loaded[modname]
end

return M
