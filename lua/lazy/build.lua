vim.opt.rtp:append(".")
local Rocks = require("lazy.pkg.rockspec")
local Semver = require("lazy.manage.semver")
local Util = require("lazy.util")

local M = {}

M.patterns = { "nvim", "treesitter", "tree-sitter", "cmp", "neo" }

function M.fetch(url, file, prefix)
  if not vim.uv.fs_stat(file) then
    print((prefix or "") .. "Fetching " .. url .. " to " .. file .. "\n")
    vim.cmd.redraw()
    local out = vim.fn.system("wget " .. url .. " -O " .. file)
    if vim.v.shell_error ~= 0 then
      pcall(vim.uv.fs_unlink, file)
      error("Failed to fetch " .. url .. ":\n" .. out)
    end
  end
end

---@return RockManifest?
function M.fetch_manifest()
  local manifest_file = "build/manifest.lua"
  M.fetch("https://luarocks.org/manifest-5.1", manifest_file)
  return Rocks.parse(manifest_file)
end

function M.fetch_rockspec(name, version, prefix)
  version = version or "scm-1"
  local url = "https://luarocks.org/" .. name .. "-" .. version .. ".rockspec"
  M.fetch(url, "build/" .. name .. ".rockspec", prefix)
end

function M.build()
  vim.fn.mkdir("build", "p")
  local manifest = M.fetch_manifest() or {}
  ---@type {name:string, version:string, url:string}[]
  local nvim_rocks = {}
  for rock, vv in pairs(manifest.repository or {}) do
    local matches = false
    for _, pattern in ipairs(M.patterns) do
      if rock:find(pattern, 1, true) then
        matches = true
        break
      end
    end
    if matches then
      local versions = vim.tbl_map(Semver.version, vim.tbl_keys(vv))
      versions = vim.tbl_filter(function(v)
        return not not v
      end, versions)
      local last = Semver.last(versions) or next(vv)
      last = type(last) == "table" and last.input or last
      table.insert(nvim_rocks, { name = rock, version = last })
    end
  end
  table.sort(nvim_rocks, function(a, b)
    return a.name < b.name
  end)

  for r, rock in ipairs(nvim_rocks) do
    local progress = string.format("[%d/%d] ", r, #nvim_rocks)
    local ok, err = pcall(M.fetch_rockspec, rock.name, rock.version, progress)
    if not ok then
      err = vim.trim("Error: " .. err)
      local lines = vim.split(err, "\n")
      lines = vim.tbl_map(function(line)
        return "    " .. line
      end, lines)
      print(table.concat(lines, "\n") .. "\n")
    end
  end

  for _, rock in ipairs(nvim_rocks) do
    local rockspec = Rocks.rockspec("build/" .. rock.name .. ".rockspec")
    if rockspec then
      local url = rockspec.source and rockspec.source.url
      -- parse github short url
      if url and url:find("://github.com/") then
        url = url:gsub("^.*://github.com/", "")
        local parts = vim.split(url, "/")
        url = parts[1] .. "/" .. parts[2]
        url = url:gsub("%.git$", "")
      end
      if url then
        rock.url = url
        print(rock.name .. " " .. url)
      else
        print("Error: " .. rock.name .. " missing source url\n\n")
        print(vim.inspect(rockspec) .. "\n")
      end
    end
  end
  Util.write_file("lua/lazy/community/_generated.lua", "return \n" .. vim.inspect(nvim_rocks))
end

M.build()

return M
