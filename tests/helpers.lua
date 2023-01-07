local Util = require("lazy.util")

local M = {}

M.fs_root = vim.fn.fnamemodify("./.tests/fs", ":p")

function M.path(path)
  return Util.norm(M.fs_root .. "/" .. path)
end

---@param files string[]
function M.fs_create(files)
  ---@type string[]
  local ret = {}

  for _, file in ipairs(files) do
    ret[#ret + 1] = Util.norm(M.fs_root .. "/" .. file)
    local parent = vim.fn.fnamemodify(ret[#ret], ":h:p")
    vim.fn.mkdir(parent, "p")
    Util.write_file(ret[#ret], "")
  end
  return ret
end

function M.fs_rm(dir)
  dir = Util.norm(M.fs_root .. "/" .. dir)
  Util.walk(dir, function(path, _, type)
    if type == "directory" then
      vim.loop.fs_rmdir(path)
    else
      vim.loop.fs_unlink(path)
    end
  end)
  vim.loop.fs_rmdir(dir)
end

return M
