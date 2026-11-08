-- Competitive Companion (browser extension) -> CompetiTest receive -> ~/Dev/jockey/cp/<judge>/<contest>/<problem>.py
local root = vim.fn.expand("~/Dev/jockey/cp")

local function slug(s)
  return (s:lower():gsub("[^%w]+", "_"):gsub("^_+", ""):gsub("_+$", ""))
end

-- Derive short, shell-friendly names from the problem URL, falling back to the group/name fields.
local function locate(task)
  local url = task.url or ""
  local contest, problem = url:match("atcoder%.jp/contests/([^/]+)/tasks/([^/?#]+)")
  if contest then
    return "atcoder", contest, (problem:gsub("^" .. vim.pesc(contest) .. "_", ""))
  end
  contest, problem = url:match("codeforces%.com/%a+/(%d+)/problem/(%w+)")
  if not contest then
    contest, problem = url:match("codeforces%.com/problemset/problem/(%d+)/(%w+)")
  end
  if contest then
    return "codeforces", contest, problem:lower()
  end
  local judge, rest = (task.group or ""):match("^(.-) %- (.+)$")
  return slug(judge or task.group or "misc"), slug(rest or "misc"), slug(task.name or "problem")
end

-- Local-only debug build: out-of-bounds, overflow and other UB abort instead of passing samples silently.
local cpp_debug_args = {
  "-std=c++23",
  "-O2",
  "-g",
  "-Wall",
  "-Wextra",
  "-Wshadow",
  "-DLOCAL",
  "-D_GLIBCXX_DEBUG",
  "-fsanitize=address,undefined",
  "-fno-sanitize-recover=all",
  "$(FNAME)",
  "-o",
  "$(FNOEXT)",
}

-- Judge-like build (Codeforces/AtCoder compile with -O2) for checking that run times fit the limit.
local cpp_judge_args = { "-std=c++23", "-O2", "-DLOCAL", "$(FNAME)", "-o", "$(FNOEXT)" }

return {
  "xeluxee/competitest.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  cmd = "CompetiTest",
  keys = {
    {
      "<leader>jr",
      function()
        vim.cmd.update()
        vim.cmd("CompetiTest run")
      end,
      desc = "Save and run testcases",
    },
    { "<leader>jc", "<cmd>CompetiTest receive contest<cr>", desc = "Receive contest" },
    { "<leader>jp", "<cmd>CompetiTest receive problem<cr>", desc = "Receive problem" },
    { "<leader>jt", "<cmd>CompetiTest receive testcases<cr>", desc = "Receive testcases" },
    { "<leader>ja", "<cmd>CompetiTest add_testcase<cr>", desc = "Add testcase" },
    { "<leader>je", "<cmd>CompetiTest edit_testcase<cr>", desc = "Edit testcase" },
    { "<leader>jd", "<cmd>CompetiTest delete_testcase<cr>", desc = "Delete testcase" },
    { "<leader>ju", "<cmd>CompetiTest show_ui<cr>", desc = "Show last results" },
    {
      "<leader>jl",
      function()
        local cfg = require("competitest.config").current_setup
        cfg.received_files_extension = cfg.received_files_extension == "py" and "cpp" or "py"
        vim.notify("CompetiTest: receiving problems as ." .. cfg.received_files_extension)
      end,
      desc = "Toggle receive language (py/cpp)",
    },
    {
      "<leader>jo",
      function()
        local config = require("competitest.config")
        local commands = require("competitest.commands")
        local cpp = config.current_setup.compile_command.cpp
        local judge = cpp.args ~= cpp_judge_args
        cpp.args = judge and cpp_judge_args or cpp_debug_args
        -- CompetiTest caches the compile command per buffer (config and runner), so drop both to pick up the change.
        for bufnr, runner in pairs(commands.runners) do
          runner:kill_all_processes()
          if runner.ui then
            runner.ui:delete()
          end
          commands.runners[bufnr] = nil
        end
        config.buffer_configs = {}
        vim.notify("CompetiTest: C++ " .. (judge and "judge build (-O2, no sanitizers)" or "debug build (sanitizers)"))
      end,
      desc = "Toggle C++ judge/debug build",
    },
  },
  opts = {
    compile_command = {
      cpp = {
        exec = "g++",
        args = cpp_judge_args,
      },
    },
    run_command = {
      -- -P keeps the problem directory off sys.path, so a solution named e.g. random.py or queue.py
      -- can't shadow the stdlib for its neighbours.
      python = { exec = "python3", args = { "-P", "$(FNAME)" } },
    },
    maximum_time = 8000,
    template_file = {
      cpp = vim.fn.stdpath("config") .. "/templates/cp.cpp",
      py = vim.fn.stdpath("config") .. "/templates/cp.py",
    },
    evaluate_template_modifiers = true,
    received_files_extension = "cpp",
    received_problems_prompt_path = false,
    received_contests_prompt_directory = false,
    received_contests_prompt_extension = false,
    received_problems_path = function(task, ext)
      local judge, contest, problem = locate(task)
      return string.format("%s/%s/%s/%s.%s", root, judge, contest, problem, ext)
    end,
    received_contests_directory = function(task)
      local judge, contest = locate(task)
      return string.format("%s/%s/%s", root, judge, contest)
    end,
    received_contests_problems_path = function(task, ext)
      local _, _, problem = locate(task)
      return problem .. "." .. ext
    end,
  },
}
