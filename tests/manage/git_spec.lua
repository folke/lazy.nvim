local Config = require("lazy.core.config")
local Git = require("lazy.manage.git")
local Process = require("lazy.manage.process")
local Util = require("lazy.util")

---@param dir string
---@return string
local function tmpdir(dir)
  dir = dir or vim.fn.tempname()
  vim.fn.mkdir(dir, "p")
  return dir
end

---@param dir string
local function git_init(dir)
  Process.exec({ "git", "-C", dir, "init", "--quiet", "--initial-branch=main" })
  Process.exec({ "git", "-C", dir, "config", "commit.gpgsign", "false" })
end

---@param repo string
---@param message string
---@param days_ago integer?
---@param author string?
---@return string commit hash
local function git_commit(repo, message, days_ago, author)
  days_ago = days_ago or 0
  local date = os.date("!%Y-%m-%dT%H:%M:%SZ", os.time() - days_ago * 86400)
  local name = author and vim.trim(author:match("^([^<]+)<")) or nil
  local email = author and author:match("<([^>]+)>") or nil
  Process.exec({
    "git", "-C", repo, "commit", "--allow-empty", "--quiet", "-m", message,
  }, {
    env = {
      GIT_AUTHOR_NAME = name or "Test",
      GIT_AUTHOR_EMAIL = email or "test@local",
      GIT_COMMITTER_NAME = name or "Test",
      GIT_COMMITTER_EMAIL = email or "test@local",
      GIT_AUTHOR_DATE = date,
      GIT_COMMITTER_DATE = date,
    },
  })
  local lines = Process.exec({ "git", "-C", repo, "rev-parse", "HEAD" })
  return lines[1]
end

---@param dir string
---@param name string
---@return string commit hash
local function git_tag(dir, name)
  Process.exec({ "git", "-C", dir, "tag", name })
  local lines = Process.exec({ "git", "-C", dir, "rev-parse", name })
  return lines[1]
end

---@param repo string
---@param branch? string
---@return string
local function head_of(repo, branch)
  local lines = Process.exec({ "git", "-C", repo, "rev-parse", branch or "HEAD" })
  return lines[1]
end

---@param plugin LazyPlugin
---@return LazyPlugin
local function with_dir(plugin)
  return vim.tbl_extend("force", plugin, {
    dir = plugin.dir,
    url = plugin.dir,
    name = plugin.name or "test",
  })
end

describe("git get_target", function()
  local repo

  before_each(function()
    repo = tmpdir()
    git_init(repo)
  end)

  after_each(function()
    if repo and vim.fn.isdirectory(repo) == 1 then
      Util.walk(repo, function(path, _, type)
        if type == "directory" then
          vim.uv.fs_rmdir(path)
        else
          vim.uv.fs_unlink(path)
        end
      end)
      vim.uv.fs_rmdir(repo)
    end
    Config.options.defaults.commit = nil
  end)

  it("returns HEAD commit for local plugin", function()
    local head = git_commit(repo, "first")
    ---@type LazyPlugin
    local plugin = with_dir({ dir = repo, _ = { is_local = true } })
    local target = Git.get_target(plugin)
    assert.same({ branch = "main", commit = head }, target)
  end)

  it("uses string plugin.commit when set", function()
    git_commit(repo, "first")
    local pinned = "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
    ---@type LazyPlugin
    local plugin = with_dir({ dir = repo, commit = pinned, _ = {} })
    local target = Git.get_target(plugin)
    assert.same({ branch = "main", commit = pinned }, target)
  end)

  it("calls function plugin.commit with natural target and uses string return", function()
    local head = git_commit(repo, "first")
    local returned = "1234567890abcdef1234567890abcdef12345678"
    local received ---@type GitTarget?
    ---@type LazyPlugin
    local plugin = with_dir({
      dir = repo,
      commit = function(target, _)
        received = target
        return returned
      end,
      _ = {},
    })
    local target = Git.get_target(plugin)
    assert.same(returned, target.commit)
    assert.same(head, received.commit)
    assert.same("main", received.branch)
    assert.same(repo, received.dir)
  end)

  it("accepts GitTarget as the hook's return value", function()
    local head = git_commit(repo, "first")
    local picked = "abcdefabcdefabcdefabcdefabcdefabcdefabcd"
    local received ---@type GitTarget?
    ---@type LazyPlugin
    local plugin = with_dir({
      dir = repo,
      commit = function(target, _)
        received = target
        return Git.target(repo, { commit = picked, branch = "main" })
      end,
      _ = {},
    })
    local target = Git.get_target(plugin)
    assert.same(picked, target.commit)
    assert.same(head, received.commit)
  end)

  it("passes through an invalid nil return value so failure can occur", function()
    git_commit(repo, "first")
    ---@type LazyPlugin
    local plugin = with_dir({
      dir = repo,
      commit = function() return nil end,
      _ = {},
    })
    local target = Git.get_target(plugin)
    assert.is_nil(target)
  end)

  it("returns nil when function plugin.commit returns nil even with tag set", function()
    git_commit(repo, "first")
    git_tag(repo, "v1.0.0")
    ---@type LazyPlugin
    local plugin = with_dir({
      dir = repo,
      tag = "v1.0.0",
      commit = function() return nil end,
      _ = {},
    })
    local target = Git.get_target(plugin)
    assert.is_nil(target)
  end)

  it("uses tag when plugin.tag is set and plugin.commit is nil", function()
    git_commit(repo, "first")
    local tag_commit = git_tag(repo, "v1.0.0")
    ---@type LazyPlugin
    local plugin = with_dir({ dir = repo, tag = "v1.0.0", _ = {} })
    local target = Git.get_target(plugin)
    assert.same(tag_commit, target.commit)
  end)

  it("uses defaults.commit function when nothing more specific is set", function()
    local head = git_commit(repo, "first")
    local returned = "abcdefabcdefabcdefabcdefabcdefabcdefabcd"
    local received ---@type GitTarget?
    Config.options.defaults.commit = function(target, _)
      received = target
      return returned
    end
    ---@type LazyPlugin
    local plugin = with_dir({ dir = repo, _ = {} })
    local target = Git.get_target(plugin)
    assert.same(returned, target.commit)
    assert.same(head, received.commit)
  end)

  it("returns nil when defaults.commit returns nil (no acceptable target)", function()
    git_commit(repo, "first")
    Config.options.defaults.commit = function() return nil end
    ---@type LazyPlugin
    local plugin = with_dir({ dir = repo, _ = {} })
    local target = Git.get_target(plugin)
    assert.is_nil(target)
  end)

  it("calls defaults.commit hook with the natural target even when plugin.tag is set", function()
    git_commit(repo, "first")
    local tag_commit = git_tag(repo, "v1.0.0")
    local returned = "abcdefabcdefabcdefabcdefabcdefabcdefabcd"
    local received ---@type GitTarget?
    Config.options.defaults.commit = function(target, _)
      received = target
      return returned
    end
    ---@type LazyPlugin
    local plugin = with_dir({ dir = repo, tag = "v1.0.0", _ = {} })
    local target = Git.get_target(plugin)
    assert.same(returned, target.commit)
    assert.same(tag_commit, received.commit)
    assert.same("v1.0.0", received.tag)
  end)

  it("prefers plugin.commit (string) over plugin.tag", function()
    git_commit(repo, "first")
    git_tag(repo, "v1.0.0")
    local pinned = "feedfacefeedfacefeedfacefeedfacefeedface"
    ---@type LazyPlugin
    local plugin = with_dir({ dir = repo, tag = "v1.0.0", commit = pinned, _ = {} })
    local target = Git.get_target(plugin)
    assert.same(pinned, target.commit)
  end)

  it("prefers plugin.commit (function) over plugin.tag and uses its return", function()
    git_commit(repo, "first")
    git_tag(repo, "v1.0.0")
    local picked = "feedfacefeedfacefeedfacefeedfacefeedface"
    ---@type LazyPlugin
    local plugin = with_dir({
      dir = repo,
      tag = "v1.0.0",
      commit = function() return picked end,
      _ = {},
    })
    local target = Git.get_target(plugin)
    assert.same(picked, target.commit)
  end)

  it("returns HEAD for local plugin even when commit function is set", function()
    local head = git_commit(repo, "first")
    local hook_called = false
    Config.options.defaults.commit = function()
      hook_called = true
      return nil
    end
    ---@type LazyPlugin
    local plugin = with_dir({ dir = repo, _ = { is_local = true } })
    local target = Git.get_target(plugin)
    assert.same(head, target.commit)
    assert.is_false(hook_called)
  end)
end)

describe("git target", function()
  local repo

  before_each(function()
    repo = tmpdir()
    git_init(repo)
  end)

  after_each(function()
    if repo and vim.fn.isdirectory(repo) == 1 then
      Util.walk(repo, function(path, _, type)
        if type == "directory" then
          vim.uv.fs_rmdir(path)
        else
          vim.uv.fs_unlink(path)
        end
      end)
      vim.uv.fs_rmdir(repo)
    end
  end)

  it("exposes commit, branch, and dir", function()
    git_commit(repo, "first")
    local target = Git.target(repo, { commit = head_of(repo), branch = "main" })
    assert.same(head_of(repo), target.commit)
    assert.same("main", target.branch)
    assert.same(repo, target.dir)
  end)

  it("short returns 7-char hash", function()
    git_commit(repo, "first")
    local target = Git.target(repo, { commit = head_of(repo), branch = "main" })
    assert.same(7, #target:short())
  end)

  it("message returns commit subject", function()
    git_commit(repo, "the message")
    local target = Git.target(repo, { commit = head_of(repo), branch = "main" })
    assert.same("the message", target:message())
  end)

  it("author returns name and email", function()
    git_commit(repo, "the message")
    local target = Git.target(repo, { commit = head_of(repo), branch = "main" })
    local author = target:author()
    assert(author:find("Test", 1, true), author)
    assert(author:find("test@local", 1, true), author)
  end)

  it("date returns a positive Unix timestamp", function()
    git_commit(repo, "first")
    local target = Git.target(repo, { commit = head_of(repo), branch = "main" })
    local ts = target:date()
    assert(ts > 0)
    assert(type(ts) == "number")
  end)

  it("age returns a number of days", function()
    git_commit(repo, "first")
    local target = Git.target(repo, { commit = head_of(repo), branch = "main" })
    local age = target:age()
    assert(type(age) == "number")
    assert(age >= 0)
  end)

  it("parent walks back through commits on the same branch", function()
    local first = git_commit(repo, "first")
    local second = git_commit(repo, "second")
    local target = Git.target(repo, { commit = second, branch = "main" })
    assert.same(second, target.commit)
    local parent = target:parent()
    assert(parent ~= nil)
    assert.same(first, parent.commit)
    assert.same("main", parent.branch)
    assert.same(repo, parent.dir)
  end)

  it("parent returns nil at the initial commit", function()
    local first = git_commit(repo, "first")
    local target = Git.target(repo, { commit = first, branch = "main" })
    assert.is_nil(target:parent())
  end)
end)

  ---@param repo string
  ---@param hook CommitHook
  local function run_hook(repo, hook)
    ---@type LazyPlugin
    local plugin = with_dir({ dir = repo, commit = hook, _ = {} })
    return Git.get_target(plugin)
  end

describe("git commit hook: restrict to human commits", function()
  local repo

  local human_author = "John Doe <john.doe@noreply.github.com>"
  local robot_author = "GitHub Copilot <copilot@github.com>"

  ---@param target GitTarget
  ---@param plugin LazyPlugin
  local function human_commit(target, _)
    ---@type GitTarget?
    local curr = target
    while curr and curr:author():match("copilot") do
      curr = curr:parent()
    end
    return curr
  end

  before_each(function()
    repo = tmpdir()
    git_init(repo)
  end)

  after_each(function()
    if repo and vim.fn.isdirectory(repo) == 1 then
      Util.walk(repo, function(path, _, type)
        if type == "directory" then
          vim.uv.fs_rmdir(path)
        else
          vim.uv.fs_unlink(path)
        end
      end)
      vim.uv.fs_rmdir(repo)
    end
    Config.options.defaults.commit = nil
  end)

  it("returns HEAD when HEAD is not authored by the robot", function()
    local head = git_commit(repo, "fresh")
    local target = run_hook(repo, human_commit)
    assert.same(head, target.commit)
  end)

  it("returns HEAD when HEAD itself is not authored by the robot", function()
    local head = git_commit(repo, "old", 5, human_author)
    local target = run_hook(repo, human_commit)
    assert.same(head, target.commit)
  end)

  it("returns nil when all commits are authored by a robot", function()
    git_commit(repo, "c1", 5, robot_author)
    git_commit(repo, "c2", 3, robot_author)
    git_commit(repo, "c3", 1, robot_author)
    assert.is_nil(run_hook(repo, human_commit))
  end)

  it("returns the newest commit that is not authored by the robot", function()
    local desired_commit = git_commit(repo, "c1", 5, human_author)
    git_commit(repo, "c2", 1, robot_author)
    git_commit(repo, "c3", 0, robot_author)
    local target = run_hook(repo, human_commit)
    assert.same(desired_commit, target.commit)
  end)
end)

describe("git commit hook: restrict to cool commits", function()
  local repo

  ---@param target GitTarget
  ---@param plugin LazyPlugin
  local function cool_commit(target, _)
    ---@type GitTarget?
    local curr = target
    while curr and curr:age() < 7 do
      curr = curr:parent()
    end
    return curr
  end

  before_each(function()
    repo = tmpdir()
    git_init(repo)
  end)

  after_each(function()
    if repo and vim.fn.isdirectory(repo) == 1 then
      Util.walk(repo, function(path, _, type)
        if type == "directory" then
          vim.uv.fs_rmdir(path)
        else
          vim.uv.fs_unlink(path)
        end
      end)
      vim.uv.fs_rmdir(repo)
    end
    Config.options.defaults.commit = nil
  end)

  it("returns nil for a single fresh commit (nothing has cooled off)", function()
    git_commit(repo, "fresh")
    assert.is_nil(run_hook(repo, cool_commit))
  end)

  it("returns HEAD when HEAD itself is more than 7 days old", function()
    local head = git_commit(repo, "old", 8)
    local target = run_hook(repo, cool_commit)
    assert.same(head, target.commit)
  end)

  it("returns nil when recent commits are rapid-fire (no commit older than 7 days)", function()
    git_commit(repo, "c1", 0)
    git_commit(repo, "c2", 0)
    git_commit(repo, "c3", 0)
    assert.is_nil(run_hook(repo, cool_commit))
  end)

  it("returns the newest commit that is older than 7 days", function()
    local oldest = git_commit(repo, "c1", 8)
    git_commit(repo, "c2", 1)
    git_commit(repo, "c3", 0)
    local target = run_hook(repo, cool_commit)
    assert.same(oldest, target.commit)
  end)

  it("returns nil when no commit is older than 7 days, even with many commits", function()
    git_commit(repo, "c1", 4)
    git_commit(repo, "c2", 3)
    git_commit(repo, "c3", 2)
    git_commit(repo, "c4", 1)
    git_commit(repo, "c5", 0)
    assert.is_nil(run_hook(repo, cool_commit))
  end)
end)

describe("git commit hook: restrict to stable commits", function()
  local repo

  ---@param target GitTarget
  ---@param plugin LazyPlugin
  local function stable_commit(target, _)
    local last_age = 0
    ---@type GitTarget?
    local curr = target
    while curr and curr:age() - last_age <= 3 do
      last_age = curr:age()
      curr = curr:parent()
    end
    return curr
  end

  before_each(function()
    repo = tmpdir()
    git_init(repo)
  end)

  after_each(function()
    if repo and vim.fn.isdirectory(repo) == 1 then
      Util.walk(repo, function(path, _, type)
        if type == "directory" then
          vim.uv.fs_rmdir(path)
        else
          vim.uv.fs_unlink(path)
        end
      end)
      vim.uv.fs_rmdir(repo)
    end
    Config.options.defaults.commit = nil
  end)

  it("returns nil for a single fresh commit (nothing has cooled off)", function()
    git_commit(repo, "fresh")
    assert.is_nil(run_hook(repo, stable_commit))
  end)

  it("returns HEAD when HEAD itself is more than 3 days old", function()
    local head = git_commit(repo, "old", 5)
    local target = run_hook(repo, stable_commit)
    assert.same(head, target.commit)
  end)

  it("returns nil when recent commits are rapid-fire (no gap exceeds 3 days)", function()
    git_commit(repo, "c1", 0)
    git_commit(repo, "c2", 0)
    git_commit(repo, "c3", 0)
    assert.is_nil(run_hook(repo, stable_commit))
  end)

  it("returns the newest commit whose gap to its successor exceeds 3 days", function()
    local oldest = git_commit(repo, "c1", 5)
    git_commit(repo, "c2", 1)
    git_commit(repo, "c3", 0)
    local target = run_hook(repo, stable_commit)
    assert.same(oldest, target.commit)
  end)

  it("picks the newest cooled-off commit, not the oldest one", function()
    git_commit(repo, "c1", 20)
    local middle = git_commit(repo, "c2", 5)
    git_commit(repo, "c3", 1)
    git_commit(repo, "c4", 0)
    local target = run_hook(repo, stable_commit)
    assert.same(middle, target.commit)
  end)

  it("returns nil when every gap is under 3 days, even with many commits", function()
    git_commit(repo, "c1", 4)
    git_commit(repo, "c2", 3)
    git_commit(repo, "c3", 2)
    git_commit(repo, "c4", 1)
    git_commit(repo, "c5", 0)
    assert.is_nil(run_hook(repo, stable_commit))
  end)
end)
