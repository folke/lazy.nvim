local Util = require("lazy.core.util")

local M = {}

---@type Async[]
M._active = {}
---@type Async[]
M._suspended = {}
M._executor = assert(vim.loop.new_check())

M.BUDGET = 10

---@type table<thread, Async>
M._threads = setmetatable({}, { __mode = "k" })

---@alias AsyncEvent "done" | "error" | "yield" | "ok"

---@class Async
---@field _co thread
---@field _fn fun()
---@field _suspended? boolean
---@field _on table<AsyncEvent, fun(res:any, async:Async)[]>
local Async = {}

---@param fn async fun()
---@return Async
function Async.new(fn)
  local self = setmetatable({}, { __index = Async })
  return self:init(fn)
end

---@param fn async fun()
---@return Async
function Async:init(fn)
  self._fn = fn
  self._on = {}
  self._co = coroutine.create(function()
    local ok, err = pcall(self._fn)
    if not ok then
      self:_emit("error", err)
    end
    self:_emit("done")
  end)
  M._threads[self._co] = self
  return M.add(self)
end

---@param event AsyncEvent
---@param cb async fun(res:any, async:Async)
function Async:on(event, cb)
  self._on[event] = self._on[event] or {}
  table.insert(self._on[event], cb)
  return self
end

---@private
---@param event AsyncEvent
---@param res any
function Async:_emit(event, res)
  for _, cb in ipairs(self._on[event] or {}) do
    cb(res, self)
  end
end

function Async:running()
  return coroutine.status(self._co) ~= "dead"
end

---@async
function Async:sleep(ms)
  vim.defer_fn(function()
    self:resume()
  end, ms)
  self:suspend()
end

---@async
---@param yield? boolean
function Async:suspend(yield)
  self._suspended = true
  if coroutine.running() == self._co and yield ~= false then
    coroutine.yield()
  end
end

function Async:resume()
  self._suspended = false
  M._run()
end

---@async
---@param yield? boolean
function Async:wake(yield)
  local async = M.running()
  assert(async, "Not in an async context")
  self:on("done", function()
    async:resume()
  end)
  async:suspend(yield)
end

---@async
function Async:wait()
  if coroutine.running() == self._co then
    error("Cannot wait on self")
  end

  local async = M.running()
  if async then
    self:wake()
  else
    while self:running() do
      vim.wait(10)
    end
  end
  return self
end

function Async:step()
  if self._suspended then
    return true
  end
  local status = coroutine.status(self._co)
  if status == "suspended" then
    local ok, res = coroutine.resume(self._co)
    if not ok then
      error(res)
    elseif res then
      self:_emit("yield", res)
    end
  end
  return self:running()
end

function M.step()
  local start = vim.uv.hrtime()
  for _ = 1, #M._active do
    if vim.uv.hrtime() - start > M.BUDGET * 1e6 then
      break
    end
    local state = table.remove(M._active, 1)
    if state:step() then
      if state._suspended then
        table.insert(M._suspended, state)
      else
        table.insert(M._active, state)
      end
    end
  end
  for _ = 1, #M._suspended do
    local state = table.remove(M._suspended, 1)
    table.insert(state._suspended and M._suspended or M._active, state)
  end

  -- print("step", #M._active, #M._suspended)
  if #M._active == 0 then
    return M._executor:stop()
  end
end

---@param async Async
function M.add(async)
  table.insert(M._active, async)
  M._run()
  return async
end

function M._run()
  if not M._executor:is_active() then
    M._executor:start(vim.schedule_wrap(M.step))
  end
end

function M.running()
  local co = coroutine.running()
  if co then
    return M._threads[co]
  end
end

---@async
---@param ms number
function M.sleep(ms)
  local async = M.running()
  assert(async, "Not in an async context")
  async:sleep(ms)
end

M.Async = Async
M.new = Async.new

return M
