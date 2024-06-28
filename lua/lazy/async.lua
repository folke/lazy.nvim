local M = {}

---@type Async[]
M._queue = {}
M._executor = assert(vim.loop.new_timer())

M.TIMER = 10
M.BUDGET = 100

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

function Async:restart()
  assert(not self:running(), "Cannot restart a running async")
  self:init(self._fn)
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
function Async:suspend()
  self._suspended = true
  if coroutine.running() == self._co then
    coroutine.yield()
  end
end

function Async:resume()
  self._suspended = false
end

function Async:wait()
  local async = M.running()
  if coroutine.running() == self._co then
    error("Cannot wait on self")
  end

  while self:running() do
    if async then
      coroutine.yield()
    else
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
  local budget = M.BUDGET * 1e6
  local start = vim.uv.hrtime()
  local count = #M._queue
  local i = 0
  while #M._queue > 0 and vim.uv.hrtime() - start < budget do
    ---@type Async
    local state = table.remove(M._queue, 1)
    if state:step() then
      table.insert(M._queue, state)
    end
    i = i + 1
    if i >= count then
      break
    end
  end
  if #M._queue == 0 then
    return M._executor:stop()
  end
end

---@param async Async
function M.add(async)
  table.insert(M._queue, async)
  if not M._executor:is_active() then
    M._executor:start(1, M.TIMER, vim.schedule_wrap(M.step))
  end
  return async
end

function M.running()
  local co = coroutine.running()
  if co then
    local async = M._threads[co]
    assert(async, "In coroutine without async context")
    return async
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
