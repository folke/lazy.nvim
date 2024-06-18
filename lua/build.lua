local M = {}

local function exec(cmd)
	return vim.system(vim.split(cmd, " "), { text = true }):wait()
end

function M.themes()
	exec("rm -rf src/themes")
	exec("mkdir -p src/themes")
	exec("cp -r .nvim/plugins/tokyonight.nvim/extras/prism src/themes/prism")
end

function M.update()
	M.themes()
end

return M
