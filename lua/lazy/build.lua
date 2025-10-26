vim.opt.rtp:append(".")
local Rocks = require("lazy.pkg.rockspec")
local Semver = require("lazy.manage.semver")
local Util = require("lazy.util")

local M = {}

M.patterns = { "nvim", "treesitter", "tree-sitter", "cmp", "neo" }
local manifest_file = "build/manifest.lua"

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

function M.split()
  local lines = vim.fn.readfile(manifest_file)
  local id = 0
  local files = {} ---@type string[]
  while #lines > 0 do
    id = id + 1
    local part_file = "build/manifest-part-" .. id .. ".lua"
    local idx = math.min(#lines, 30000)
    while idx < #lines and not lines[idx]:match("^   },$") do
      idx = idx + 1
    end
    local part_lines = vim.list_slice(lines, 1, idx)
    if idx ~= #lines then
      part_lines[#part_lines] = "   }}"
    end
    vim.fn.writefile(part_lines, part_file)
    files[#files + 1] = part_file
    print("Wrote " .. part_file .. "\n")

    lines = vim.list_slice(lines, idx + 1)
    if #lines == 0 then
      break
    end
    lines[1] = "repository = { " .. lines[1]
  end
  return files
end

---@return RockManifest?
function M.fetch_manifest()
  M.fetch("https://luarocks.org/manifest-5.1", manifest_file)
  local ret = { repository = {} }
  for _, file in ipairs(M.split()) do
    local part = Rocks.parse(file)
    print(vim.tbl_count(part.repository or {}) .. " rocks in " .. file .. "\n")
    for k, v in pairs(part.repository or {}) do
      ret.repository[k] = v
    end
  end
  return ret
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
  print(vim.tbl_count(manifest.repository or {}) .. " rocks in manifest\n")
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
