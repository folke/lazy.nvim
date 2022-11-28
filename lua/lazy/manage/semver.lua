local M = {}

---@class Semver
---@field [1] number
---@field [2] number
---@field [3] number
---@field major number
---@field minor number
---@field patch number
---@field prerelease? string
---@field build? string
local Semver = {}
Semver.__index = Semver

function Semver:__index(key)
  return type(key) == "number" and ({ self.major, self.minor, self.patch })[key] or Semver[key]
end

function Semver:__newindex(key, value)
  if key == 1 then
    self.major = value
  elseif key == 2 then
    self.minor = value
  elseif key == 3 then
    self.patch = value
  else
    rawset(self, key, value)
  end
end

---@param other Semver
function Semver:__eq(other)
  for i = 1, 3 do
    if self[i] ~= other[i] then
      return false
    end
  end
  return self.prerelease == other.prerelease
end

function Semver:__tostring()
  local ret = table.concat({ self.major, self.minor, self.patch }, ".")
  if self.prerelease then
    ret = ret .. "-" .. self.prerelease
  end
  if self.build then
    ret = ret .. "+" .. self.build
  end
  return ret
end

---@param other Semver
function Semver:__lt(other)
  for i = 1, 3 do
    if self[i] > other[i] then
      return false
    elseif self[i] < other[i] then
      return true
    end
  end
  if self.prerelease and not other.prerelease then
    return true
  end
  if other.prerelease and not self.prerelease then
    return false
  end
  return (self.prerelease or "") < (other.prerelease or "")
end

---@param other Semver
function Semver:__le(other)
  return self < other or self == other
end

---@param version string|number[]
---@return Semver?
function M.version(version)
  if type(version) == "table" then
    return setmetatable({
      major = version[1] or 0,
      minor = version[2] or 0,
      patch = version[3] or 0,
    }, Semver)
  end
  local major, minor, patch, prerelease, build = version:match("^v?(%d+)%.?(%d*)%.?(%d*)%-?([^+]*)+?(.*)$")
  if major then
    return setmetatable({
      major = tonumber(major),
      minor = minor == "" and 0 or tonumber(minor),
      patch = patch == "" and 0 or tonumber(patch),
      prerelease = prerelease ~= "" and prerelease or nil,
      build = build ~= "" and build or nil,
    }, Semver)
  end
end

---@generic T: Semver
---@param versions T[]
---@return T?
function M.last(versions)
  local last = versions[1]
  for i = 2, #versions do
    if versions[i] > last then
      last = versions[i]
    end
  end
  return last
end

---@class SemverRange
---@field from Semver
---@field to? Semver
local Range = {}

---@param version string|Semver
function Range:matches(version)
  if type(version) == "string" then
    ---@diagnostic disable-next-line: cast-local-type
    version = M.version(version)
  end
  if version then
    if version.prerelease ~= self.from.prerelease then
      return false
    end
    return version >= self.from and (self.to == nil or version < self.to)
  end
end

---@param spec string
function M.range(spec)
  if spec == "*" or spec == "" then
    return setmetatable({ from = M.version("0.0.0") }, { __index = Range })
  end

  ---@type number?
  local hyphen = spec:find(" - ", 1, true)
  if hyphen then
    local a = spec:sub(1, hyphen - 1)
    local b = spec:sub(hyphen + 3)
    local parts = vim.split(b, ".", { plain = true })
    local ra = M.range(a)
    local rb = M.range(b)
    return setmetatable({
      from = ra and ra.from,
      to = rb and (#parts == 3 and rb.from or rb.to),
    }, { __index = Range })
  end
  ---@type string, string
  local mods, version = spec:lower():match("^([%^=>~]*)(.*)$")
  version = version:gsub("%.[%*x]", "")
  local parts = vim.split(version:gsub("%-.*", ""), ".", { plain = true })
  if #parts < 3 and mods == "" then
    mods = "~"
  end

  local semver = M.version(version)
  if semver then
    local from = semver
    local to = vim.deepcopy(semver)
    if mods == "" or mods == "=" then
      to.patch = to.patch + 1
    elseif mods == ">" then
      from.patch = from.patch + 1
      to = nil
    elseif mods == ">=" then
      to = nil
    elseif mods == "~" then
      if #parts >= 2 then
        to[2] = to[2] + 1
        to[3] = 0
      else
        to[1] = to[1] + 1
        to[2] = 0
        to[3] = 0
      end
    elseif mods == "^" then
      for i = 1, 3 do
        if to[i] ~= 0 then
          to[i] = to[i] + 1
          for j = i + 1, 3 do
            to[j] = 0
          end
          break
        end
      end
    end
    return setmetatable({ from = from, to = to }, { __index = Range })
  end
end

return M
