-- Git workflows behind the <leader>g keys. Diffs open in CodeDiff; GitHub goes through Snacks.gh.
local M = {}

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Git" })
end

local function git(args, cwd)
  local result = vim.system(vim.list_extend({ "git" }, args), { cwd = cwd, text = true }):wait()
  return result.code == 0 and vim.trim(result.stdout or "") or nil, result
end

local function root()
  local file = vim.api.nvim_buf_get_name(0)
  local start = file ~= "" and vim.fs.dirname(file) or vim.uv.cwd()
  return git({ "rev-parse", "--show-toplevel" }, start)
end

-- origin's default branch (as origin/<name>), else a local main or master.
function M.default_branch(cwd)
  local remote = git({ "symbolic-ref", "--quiet", "--short", "refs/remotes/origin/HEAD" }, cwd)
  if remote then
    return remote
  end
  for _, name in ipairs({ "origin/main", "origin/master", "main", "master" }) do
    if git({ "rev-parse", "--verify", "--quiet", name }, cwd) then
      return name
    end
  end
end

-- What a pull request from this branch would contain: changes since it left the default branch.
function M.branch_changes()
  local cwd = root()
  local base = cwd and M.default_branch(cwd)
  if not base then
    notify("No default branch found (origin/HEAD, main or master)", vim.log.levels.WARN)
    return
  end
  vim.cmd("CodeDiff " .. base .. "...")
end

-- Diff against a branch you pick, local or remote.
function M.diff_against()
  Snacks.picker.git_branches({
    all = true,
    title = "Diff against branch",
    confirm = function(picker, item)
      picker:close()
      if item and item.branch then
        vim.cmd("CodeDiff " .. item.branch)
      end
    end,
  })
end

-- Fetches, then shows the upstream commits this branch doesn't have yet, each with its diff.
function M.incoming()
  local cwd = root()
  if not cwd then
    notify("Not in a git repository", vim.log.levels.WARN)
    return
  end
  notify("Fetching…")
  vim.system({ "git", "fetch", "--quiet" }, { cwd = cwd, text = true }, function(fetch)
    vim.schedule(function()
      local upstream = git({ "rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}" }, cwd)
      if not upstream then
        notify("This branch has no upstream to compare with", vim.log.levels.WARN)
        return
      end
      if fetch.code ~= 0 then
        notify("Fetch failed, showing what's already known: " .. vim.trim(fetch.stderr or ""), vim.log.levels.WARN)
      end
      local count = tonumber((git({ "rev-list", "--count", "HEAD.." .. upstream }, cwd))) or 0
      if count == 0 then
        notify("Up to date with " .. upstream)
        return
      end
      notify(("%d incoming commit%s from %s"):format(count, count == 1 and "" or "s", upstream))
      vim.cmd("CodeDiff history HEAD.." .. upstream)
    end)
  end)
end

-- Resolves conflicts in this file, or opens the explorer on the repo's conflicted files.
function M.conflicts()
  local cwd = root()
  local file = vim.api.nvim_buf_get_name(0)
  local unmerged = cwd and git({ "diff", "--name-only", "--diff-filter=U" }, cwd) or ""
  if unmerged == "" then
    notify("No merge conflicts")
    return
  end
  local relative = cwd and file:sub(#cwd + 2)
  if relative and vim.tbl_contains(vim.split(unmerged, "\n"), relative) then
    vim.cmd("CodeDiff merge " .. vim.fn.fnameescape(file))
  else
    vim.cmd("CodeDiff")
  end
end

local function open_in_tmux(path, name)
  if vim.env.TMUX then
    vim.system({ "tmux", "new-window", "-n", name, "-c", path, "nvim" }):wait()
  else
    vim.cmd.tabnew()
    vim.cmd.tcd(vim.fn.fnameescape(path))
    vim.cmd.edit(".")
  end
end

-- Worktrees: switch to one, or start an offshoot (a new branch in its own folder and tmux
-- window), for trying an idea or letting an agent work without touching this checkout.
function M.worktrees()
  local cwd = root()
  if not cwd then
    notify("Not in a git repository", vim.log.levels.WARN)
    return
  end
  local items = { { new = true, text = "New worktree…" } }
  local current = {}
  for line in ((git({ "worktree", "list", "--porcelain" }, cwd) or "") .. "\n"):gmatch("(.-)\n") do
    local path = line:match("^worktree (.+)")
    if path then
      current = { path = path, text = path }
      items[#items + 1] = current
    end
    local branch = line:match("^branch refs/heads/(.+)")
    if branch then
      current.branch, current.text = branch, branch .. "  " .. current.path
    end
  end
  vim.ui.select(items, {
    prompt = "Worktrees",
    format_item = function(item)
      return item.text
    end,
  }, function(choice)
    if not choice then
      return
    end
    if not choice.new then
      open_in_tmux(choice.path, choice.branch or vim.fs.basename(choice.path))
      return
    end
    vim.ui.input({ prompt = "New branch: " }, function(branch)
      if not branch or branch == "" then
        return
      end
      local path = vim.fs.joinpath(vim.fs.dirname(cwd), vim.fs.basename(cwd) .. "-" .. branch:gsub("/", "-"))
      local _, result = git({ "worktree", "add", "-b", branch, path }, cwd)
      if result.code ~= 0 then
        notify("git worktree add failed: " .. vim.trim(result.stderr or ""), vim.log.levels.ERROR)
        return
      end
      notify("Worktree " .. branch .. " at " .. path)
      open_in_tmux(path, branch)
    end)
  end)
end

-- Pull requests: Enter for actions (view, comment, review, checkout, merge), <C-d> to
-- review the PR side by side in CodeDiff without checking it out.
function M.pull_requests()
  if vim.fn.executable("gh") == 0 then
    notify("gh (GitHub CLI) is not installed", vim.log.levels.ERROR)
    return
  end
  local cwd = root()
  local remote = cwd and git({ "remote", "get-url", "origin" }, cwd) or ""
  if not remote:find("github.com", 1, true) then
    notify("origin is not a GitHub repository", vim.log.levels.WARN)
    return
  end
  Snacks.picker.gh_pr({
    actions = {
      codediff = function(picker, item)
        picker:close()
        if item and item.number then
          vim.cmd("CodeDiff pr " .. item.number)
        end
      end,
    },
    win = { input = { keys = { ["<c-d>"] = { "codediff", mode = { "n", "i" }, desc = "Review in CodeDiff" } } } },
  })
end

return M
