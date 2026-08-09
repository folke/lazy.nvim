local Git = require("lazy.manage.git")
local Helpers = require("tests.helpers")
local Process = require("lazy.manage.process")
local Util = require("lazy.util")

local unpack = unpack or table.unpack

local function run_git(repo, ...)
  local lines, code = Process.exec({ "git", ... }, { cwd = repo })
  assert.are.equal(0, code)
  return lines
end

describe("git manage", function()
  local repo_dir = Helpers.path("test_repo")

  local function setup_repo(ref_format)
    Helpers.fs_rm("test_repo")
    vim.fn.mkdir(repo_dir, "p")
    local init_args = { "init", "-b", "main" }
    if ref_format then
      table.insert(init_args, "--ref-format=" .. ref_format)
    end
    local _, code = Process.exec({ "git", unpack(init_args) }, { cwd = repo_dir })
    if code ~= 0 then
      return false
    end
    run_git(repo_dir, "config", "user.name", "Test User")
    run_git(repo_dir, "config", "user.email", "test@example.com")
    Util.write_file(repo_dir .. "/file.txt", "hello")
    run_git(repo_dir, "add", "file.txt")
    run_git(repo_dir, "commit", "-m", "initial commit")
    run_git(repo_dir, "tag", "v1.0.0")
    Util.write_file(repo_dir .. "/file.txt", "hello world")
    run_git(repo_dir, "commit", "-am", "second commit")
    run_git(repo_dir, "tag", "-a", "v1.1.0", "-m", "annotated release")
    return true
  end

  after_each(function()
    Helpers.fs_rm("test_repo")
  end)

  for _, format in ipairs({ "files", "reftable" }) do
    describe("ref format: " .. format, function()
      it("resolves head, info, tags, and refs", function()
        if not setup_repo(format) then
          return
        end

        -- Info (Attached)
        local info = Git.info(repo_dir)
        assert.is_not_nil(info)
        assert.are.equal("main", info.branch)
        assert.are.equal("v1.1.0", info.tag)
        assert.is_not_nil(info.version)
        assert.are.equal(1, info.version.major)
        assert.are.equal(1, info.version.minor)

        -- Tags
        local tags = Git.get_tags(repo_dir)
        table.sort(tags)
        assert.are.same({ "v1.0.0", "v1.1.0" }, tags)

        -- Refs
        local commit = Git.ref(repo_dir, "heads", "main")
        assert.is_not_nil(commit)
        assert.are.equal(info.commit, commit)

        -- Tag ref (Lightweight)
        local tag_commit = Git.ref(repo_dir, "tags", "v1.0.0")
        assert.is_not_nil(tag_commit)

        -- Tag ref (Annotated - should peel to commit)
        local annotated_commit = Git.ref(repo_dir, "tags", "v1.1.0")
        assert.are.equal(info.commit, annotated_commit)

        -- Util.git_info
        local uinfo = Util.git_info(repo_dir)
        assert.is_not_nil(uinfo)
        assert.are.equal("main", uinfo.branch)
        assert.are.equal(info.commit, uinfo.hash)

        -- Info (Detached HEAD)
        run_git(repo_dir, "checkout", "v1.0.0")
        local detached_info = Git.info(repo_dir)
        assert.is_not_nil(detached_info)
        assert.is_nil(detached_info.branch)
        assert.are.equal(tag_commit, detached_info.commit)
        assert.are.equal("v1.0.0", detached_info.tag)
      end)
    end)
  end
end)
