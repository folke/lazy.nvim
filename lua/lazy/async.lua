---@class AsyncOpts
---@field on_done? fun()
---@field on_error? fun(err:string)
---@field on_yield? fun(res:any)

local M = {}

---@type Async[]
M._queue = {}
M._executor = assert(vim.loop.new_check())
M._running = false

---@class Async
---@field co thread
---@field opts AsyncOpts
local Async = {}

---@param fn async fun()
---@param opts? AsyncOpts
---@return Async
function Async.new(fn, opts)
  local self = setmetatable({}, { __index = Async })
  self.co = coroutine.create(fn)
  self.opts = opts or {}
  return self
end

function Async:running()
  return coroutine.status(self.co) ~= "dead"
end

function Async:step()
  local status = coroutine.status(self.co)
  if status == "suspended" then
    local ok, res = coroutine.resume(self.co)
    if not ok then
      if self.opts.on_error then
        self.opts.on_error(tostring(res))
      end
    elseif res then
      if self.opts.on_yield then
        self.opts.on_yield(res)
      end
    end
  end
  if self:running() then
    return true
  end
  if self.opts.on_done then
    self.opts.on_done()
  end
end

function M.step()
  M._running = true
  local budget = 1 * 1e6
  local start = vim.loop.hrtime()
  local count = #M._queue
  local i = 0
  while #M._queue > 0 and vim.loop.hrtime() - start < budget do
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
  M._running = false
  if #M._queue == 0 then
    return M._executor:stop()
  end
end

---@param async Async
function M.add(async)
  table.insert(M._queue, async)
  if not M._executor:is_active() then
    M._executor:start(vim.schedule_wrap(M.step))
  end
  return async
end

---@param fn async fun()
---@param opts? AsyncOpts
function M.run(fn, opts)
  return M.add(Async.new(fn, opts))
end

---@generic T: async fun()
---@param fn T
---@param opts? AsyncOpts
---@return T
function M.wrap(fn, opts)
  return function(...)
    local args = { ... }
    ---@async
    local wrapped = function()
      return fn(unpack(args))
    end
    return M.run(wrapped, opts)
  end
end

return M
