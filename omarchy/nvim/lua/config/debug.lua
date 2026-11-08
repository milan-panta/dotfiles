-- "Debug this": one key starts the right debugger for the file's language.
-- Also the session helpers behind the <leader>d keys. Builds live in config.build,
-- breakpoints in config.breakpoints.

local M = {}

local build = require("config.build")

local function current_file()
  return vim.api.nvim_buf_get_name(0)
end

local function is_executable(path)
  local stat = path and vim.uv.fs_stat(path)
  return stat and stat.type == "file" and vim.fn.executable(path) == 1
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Debug" })
end

function M.parse_args(input)
  local args, current = {}, {}
  local quote = nil
  local escaped = false
  local started = false

  local function finish_arg()
    if started then
      args[#args + 1] = table.concat(current)
      current = {}
      started = false
    end
  end

  for i = 1, #input do
    local char = input:sub(i, i)
    if escaped then
      current[#current + 1] = char
      escaped = false
      started = true
    elseif char == "\\" and quote ~= "'" then
      escaped = true
      started = true
    elseif quote then
      if char == quote then
        quote = nil
      else
        current[#current + 1] = char
      end
      started = true
    elseif char == "'" or char == '"' then
      quote = char
      started = true
    elseif char:match("%s") then
      finish_arg()
    else
      current[#current + 1] = char
      started = true
    end
  end

  if escaped then
    return nil, "trailing escape in arguments"
  end
  if quote then
    return nil, "unterminated " .. quote .. " quote in arguments"
  end

  finish_arg()
  return args
end

function M.prompt_args()
  while true do
    local args, err = M.parse_args(vim.fn.input("Args: "))
    if args then
      return args
    end
    vim.notify(err, vim.log.levels.ERROR)
  end
end

-- ---------------------------------------------------------------------------
-- "Debug this": one key, the right thing per language.
-- ---------------------------------------------------------------------------

local function save()
  if vim.bo.modified and vim.bo.buftype == "" and current_file() ~= "" then
    vim.cmd.write()
  end
end

-- The project's interpreter: an active venv, then the nearest .venv, then the system's.
function M.python_for(file)
  if vim.env.VIRTUAL_ENV then
    return vim.env.VIRTUAL_ENV .. "/bin/python"
  end
  local root = vim.fs.root(file, ".venv")
  local venv = root and vim.fs.joinpath(root, ".venv/bin/python")
  return venv and vim.fn.executable(venv) == 1 and venv or "python3"
end

local function python_root(file)
  return vim.fs.root(file, { "pyproject.toml", "uv.lock", ".venv", "setup.py", ".git" }) or vim.fs.dirname(file)
end

-- A launch config for the current Python file. `src/` goes on the path, as the IDEs do for a source root.
function M.python_config(extra)
  local file = current_file()
  local root = python_root(file)
  local env
  if vim.fn.isdirectory(vim.fs.joinpath(root, "src")) == 1 then
    local existing = vim.env.PYTHONPATH
    env = { PYTHONPATH = vim.fs.joinpath(root, "src") .. (existing and (":" .. existing) or "") }
  end
  return vim.tbl_extend("force", {
    type = "python",
    request = "launch",
    name = "Debug " .. vim.fs.basename(file),
    program = file,
    cwd = root,
    console = "integratedTerminal",
    python = { M.python_for(file) },
    env = env,
  }, extra or {})
end

-- `debugpy --listen` is itself a debug server, so attaching connects straight to it.
function M.python_adapter(launch_adapter)
  return function(callback, config)
    if config.request ~= "attach" then
      callback(launch_adapter)
      return
    end
    local connect = config.connect or { host = config.host, port = config.port }
    if type(connect) == "function" then
      connect = connect()
    end
    callback({ type = "server", host = connect.host or "127.0.0.1", port = connect.port })
  end
end

local function has_adapter(name, install_hint)
  if require("dap").adapters[name] then
    return true
  end
  notify(("No debug adapter `%s`. %s"):format(name, install_hint), vim.log.levels.ERROR)
  return false
end

local function cursor_in_neotest_test(file, line)
  local neotest = package.loaded.neotest
  if not neotest then
    return false
  end
  for _, id in ipairs(neotest.state.adapter_ids()) do
    local tree = neotest.state.positions(id)
    local node = tree and tree:get_key(file)
    if node then
      for _, child in node:iter_nodes() do
        local d = child:data()
        if d.type == "test" and d.range and d.range[1] + 1 <= line and line <= d.range[3] + 1 then
          return true
        end
      end
    end
  end
  return false
end

local function debug_python()
  local file = current_file()
  if not has_adapter("python", "Install it with :MasonInstall debugpy") then
    return
  end
  local name = vim.fs.basename(file)
  local is_test_file = name:match("^test_.*%.py$") or name:match("_test%.py$")
  if is_test_file or cursor_in_neotest_test(file, vim.fn.line(".")) then
    require("config.neotest_run").run({ strategy = "dap" })
    return
  end
  require("dap").run(M.python_config())
end

-- ---------------------------------------------------------------------------
-- C and C++: build, pick the program, give it stdin.
-- ---------------------------------------------------------------------------

local chosen_program = {} -- project root -> program picked last time
local stdin_pane = nil

local function reads_stdin(file)
  local ok, lines = pcall(vim.fn.readfile, file)
  if not ok then
    return false
  end
  local text = table.concat(lines, "\n")
  return text:find("cin", 1, true) ~= nil
    or text:find("scanf", 1, true) ~= nil
    or text:find("getline", 1, true) ~= nil
    or text:find("getchar", 1, true) ~= nil
    or text:find("fgets", 1, true) ~= nil
end

-- CompetiTest names samples <stem>_input<N>.txt, next to the source.
local function sample_inputs(file)
  local dir, stem = vim.fs.dirname(file), vim.fn.fnamemodify(file, ":t:r")
  local out = {}
  for name, kind in vim.fs.dir(dir) do
    local n = kind == "file" and name:match("^" .. vim.pesc(stem) .. "_input(%d+)%.txt$")
    if n then
      out[#out + 1] = { path = vim.fs.joinpath(dir, name), n = tonumber(n), name = name }
    end
  end
  table.sort(out, function(a, b)
    return a.n < b.n
  end)
  return out
end

-- Runs the program's stdin and stdout in a tmux pane. gdb's DAP mode gives a program
-- /dev/null otherwise. The pane stays after exit so the output can be read.
local function open_stdin_pane(root)
  if not vim.env.TMUX then
    return nil
  end
  if stdin_pane then
    vim.system({ "tmux", "kill-pane", "-t", stdin_pane }):wait()
    stdin_pane = nil
  end
  local split = { "tmux", "split-window", "-h", "-d", "-l", "35%", "-P", "-F", "#{pane_id} #{pane_tty}", "-c", root }
  if vim.env.TMUX_PANE then
    vim.list_extend(split, { "-t", vim.env.TMUX_PANE })
  end
  split[#split + 1] = "sleep infinity"
  local result = vim.system(split, { text = true }):wait()
  if result.code ~= 0 then
    return nil
  end
  local id, tty = result.stdout:match("^(%S+) (%S+)")
  stdin_pane = id
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = vim.api.nvim_create_augroup("debug_stdin_pane", { clear = true }),
    callback = function()
      if stdin_pane then
        vim.system({ "tmux", "kill-pane", "-t", stdin_pane }):wait()
      end
    end,
  })
  return tty
end

-- gdb's options for one run. `config.stdin` is a file, `config.tty` a terminal.
function M.gdb_args(config)
  local args = {
    "--interpreter=dap",
    "--eval-command",
    "set print pretty on",
    "--eval-command",
    "set debuginfod enabled off",
    -- Step over the standard library, as "just my code" does for Python.
    "--eval-command",
    "skip -gfi /usr/include/*",
  }
  if config.stdin then
    vim.list_extend(args, {
      "--eval-command",
      -- The input file is $0 and gdb appends the program, so spaces in the path are safe.
      -- One sh exec only: gdb expects a wrapper to exec exactly once.
      ('set exec-wrapper sh -c \'exec "$@" < "$0"\' %s'):format(vim.fn.shellescape(config.stdin)),
    })
  elseif config.tty then
    vim.list_extend(args, { "--eval-command", "set inferior-tty " .. config.tty })
  end
  return args
end

-- input: nil means choose by itself; otherwise { path = file } or { interactive = true } or { none = true }.
local function resolve_stdin(file, root, input)
  input = input or {}
  if input.none then
    return {}
  end
  if input.path then
    return { stdin = input.path }
  end
  if not input.interactive then
    local samples = sample_inputs(file)
    if samples[1] then
      notify("stdin: " .. samples[1].name)
      return { stdin = samples[1].path }
    end
    if not reads_stdin(file) then
      return {}
    end
  end
  local tty = open_stdin_pane(root)
  if tty then
    notify("Type the program's input in the tmux pane on the right")
    return { tty = tty }
  end
  notify("stdin is empty outside tmux. Add " .. vim.fn.fnamemodify(file, ":t:r") .. "_input0.txt", vim.log.levels.WARN)
  return {}
end

local function with_program(root, standalone_output, callback)
  if standalone_output then
    return callback(standalone_output)
  end
  local remembered = chosen_program[root]
  if remembered and is_executable(remembered) then
    return callback(remembered)
  end
  local candidates = build.executable_candidates()
  if #candidates == 1 then
    chosen_program[root] = candidates[1]
    return callback(candidates[1])
  end
  if #candidates == 0 then
    notify("Build finished, but no program was found under " .. root, vim.log.levels.ERROR)
    return
  end
  vim.ui.select(candidates, {
    prompt = "Debug which program?",
    format_item = function(path)
      return path:sub(#root + 2)
    end,
  }, function(choice)
    if choice then
      chosen_program[root] = choice
      callback(choice)
    end
  end)
end

local function debug_native(input)
  if vim.fn.executable("gdb") == 0 then
    notify("gdb is not installed", vim.log.levels.ERROR)
    return
  end
  local file = current_file()
  local project = build.build_plan()
  local plan = project or build.standalone_build()
  build.run_commands(plan, function()
    local standalone_output = not project and vim.fn.fnamemodify(file, ":r") or nil
    with_program(plan.root, standalone_output, function(program)
      local stdin = resolve_stdin(file, plan.root, input)
      require("dap").run(vim.tbl_extend("force", {
        name = "Debug " .. vim.fs.basename(program),
        type = "gdb",
        request = "launch",
        program = program,
        cwd = plan.root,
        stopAtBeginningOfMainSubprogram = false,
      }, stdin))
    end)
  end)
end

-- Debug with a chosen sample, an interactive pane, or nothing on stdin.
function M.debug_with_input()
  if vim.bo.filetype ~= "c" and vim.bo.filetype ~= "cpp" then
    M.debug_this()
    return
  end
  save()
  local file = current_file()
  local choices = {}
  for _, sample in ipairs(sample_inputs(file)) do
    choices[#choices + 1] = { label = sample.name, input = { path = sample.path } }
  end
  choices[#choices + 1] = { label = "Type it in a tmux pane", input = { interactive = true } }
  choices[#choices + 1] = { label = "No input", input = { none = true } }
  vim.ui.select(choices, {
    prompt = "Program input",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if choice then
      debug_native(choice.input)
    end
  end)
end

local function debug_go()
  if not has_adapter("delve", "Install it with :MasonInstall delve") then
    return
  end
  local file = current_file()
  local dir = vim.fs.dirname(file)
  local test
  if file:match("_test%.go$") then
    for line = vim.fn.line("."), 1, -1 do
      test = vim.fn.getline(line):match("^func%s+(Test%w*)%s*%(")
      if test then
        break
      end
    end
  end
  require("dap").run({
    type = "delve",
    request = "launch",
    name = test and ("Debug " .. test) or "Debug package",
    mode = file:match("_test%.go$") and "test" or "debug",
    program = dir,
    cwd = vim.fs.root(file, "go.mod") or dir,
    args = test and { "-test.run", "^" .. test .. "$" } or nil,
  })
end

-- hdb (Well-Typed's haskell-debugger) runs the program in its own GHC session; it only
-- works with the GHC it was built for (9.14.1 here).
local function debug_haskell()
  if vim.fn.executable("hdb") == 0 then
    notify("hdb is not installed. See the Haskell section of the config README.", vim.log.levels.ERROR)
    return
  end
  if not vim.env.TMUX then
    notify("Haskell debugging runs the program in a tmux pane; start Neovim inside tmux.", vim.log.levels.ERROR)
    return
  end
  local file = current_file()
  local root = vim.fs.root(file, function(name)
    return name:match("%.cabal$") ~= nil or name == "cabal.project" or name == "stack.yaml"
  end) or vim.fs.dirname(file)

  -- hdb starts the program's terminal side as a second hdb process, which needs GHC's
  -- libraries. Only that tmux pane gets them: GHC's lib dir also holds a libffi that
  -- mustn't leak into everything else Neovim starts.
  local libdir = vim.trim(vim.system({ "ghc-9.14.1", "--print-libdir" }, { text = true }):wait().stdout or "")
  local dirs = vim.tbl_filter(function(dir)
    return vim.fn.isdirectory(dir) == 1
  end, vim.fn.glob(libdir .. "/*", false, true))
  for _, pane in
    ipairs(
      vim.split(
        vim.system({ "tmux", "list-panes", "-F", "#{pane_id} #{pane_title}" }, { text = true }):wait().stdout or "",
        "\n"
      )
    )
  do
    local id, title = pane:match("^(%S+) (.*)$")
    if title == "hdb-debuggee" then
      vim.system({ "tmux", "kill-pane", "-t", id }):wait()
    end
  end
  local split = { "split-window", "-h", "-d", "-l", "35%", "-e", "LD_LIBRARY_PATH=" .. table.concat(dirs, ":") }
  if vim.env.TMUX_PANE then
    vim.list_extend(split, { "-t", vim.env.TMUX_PANE })
  end
  -- Keep the pane after the program ends, so its output can be read.
  vim.list_extend(split, {
    "sh",
    "-c",
    'tmux select-pane -T hdb-debuggee; "$@"; echo; echo "[program finished]"; exec sleep infinity',
    "sh",
  })
  local dap = require("dap")
  dap.defaults.haskell.force_external_terminal = true
  dap.defaults.haskell.external_terminal = { command = "tmux", args = split }

  dap.run({
    type = "haskell",
    request = "launch",
    name = "Debug " .. vim.fs.basename(file),
    projectRoot = root,
    entryFile = file:sub(#root + 2),
    entryPoint = "main",
    entryArgs = {},
    extraGhcArgs = {},
  })
end

local function debug_rust()
  if #vim.lsp.get_clients({ bufnr = 0, name = "rust-analyzer" }) == 0 then
    notify("rust-analyzer is still starting. Try again in a moment.", vim.log.levels.WARN)
    return
  end
  vim.cmd.RustLsp("debug")
end

local signal_names = {
  [4] = "SIGILL, illegal instruction",
  [6] = "SIGABRT, aborted",
  [7] = "SIGBUS, bus error",
  [8] = "SIGFPE, arithmetic error",
  [11] = "SIGSEGV, segmentation fault",
}

-- gdb reports a crash as reason "signal" with no name, so ask it which signal this was.
function M.on_stopped(session, body)
  if not body or body.reason ~= "signal" then
    return
  end
  session:request("evaluate", { expression = "$_siginfo.si_signo", context = "watch" }, function(_, response)
    local number = response and tonumber(response.result)
    notify("Program crashed: " .. (signal_names[number] or ("signal " .. tostring(number))), vim.log.levels.ERROR)
  end)
end

-- Whether stepping and stops stay in your own code. Applies from the next session.
M.just_my_code = true

function M.toggle_just_my_code()
  M.just_my_code = not M.just_my_code
  notify("Just my code " .. (M.just_my_code and "on" or "off: library frames included") .. ", from the next session")
end

function M.apply_just_my_code(config)
  if config.type == "python" or config.type == "debugpy" then
    config = vim.deepcopy(config)
    config.justMyCode = M.just_my_code
  end
  return config
end

-- While stopped, K shows the value under the cursor; otherwise it does what it always did.
function M.hover_or(fallback)
  local dap = package.loaded.dap
  local session = dap and dap.session()
  if session and session.stopped_thread_id then
    vim.cmd.DapViewHover()
  else
    fallback()
  end
end

function M.restart()
  local dap = require("dap")
  if dap.session() then
    dap.restart()
  else
    dap.run_last()
  end
end

-- Stops the session, or closes the view if nothing is running.
function M.stop()
  local dap = require("dap")
  if dap.session() then
    dap.terminate()
  else
    vim.cmd("DapViewClose!")
  end
end

function M.watch()
  vim.cmd.DapViewWatch()
  require("dap-view").open()
  vim.cmd.DapViewShow("watches")
end

-- Which exceptions stop the program. The Exceptions tab only works during a session,
-- so with none running this lists the filters the adapter offered last time.
function M.exception_stops()
  local dap = require("dap")
  if dap.session() then
    M.jump("exceptions")
    return
  end
  local adapter = ({ python = "python", c = "gdb", cpp = "gdb", go = "delve" })[vim.bo.filetype] or vim.bo.filetype
  local options = require("dap-view.state").exceptions_options[adapter]
  if not options or #options == 0 then
    notify("Start a debug session once to see the exception filters for " .. adapter)
    return
  end
  vim.ui.select(options, {
    prompt = "Stop on exceptions (toggle)",
    format_item = function(option)
      return (option.enabled and "[x] " or "[ ] ") .. option.exception_filter.label
    end,
  }, function(choice)
    if choice then
      choice.enabled = not choice.enabled
      -- nvim-dap sends these while the session starts, before any code runs.
      dap.defaults[adapter].exception_breakpoints = vim
        .iter(options)
        :filter(function(option)
          return option.enabled
        end)
        :map(function(option)
          return option.exception_filter.filter
        end)
        :totable()
      notify(choice.exception_filter.label .. (choice.enabled and ": on" or ": off"))
    end
  end)
end

-- Opens the debug view if needed and jumps to one of its tabs.
function M.jump(view)
  require("dap-view").open()
  vim.cmd.DapViewJump(view)
end

-- Focuses the program's terminal, for programs that read input().
function M.focus_console()
  -- debugpy runs the program in a child session; the terminal belongs to its parent.
  local session = require("dap").session()
  local buf
  while session and not buf do
    buf = session.term_buf
    session = session.parent
  end
  if buf and vim.api.nvim_buf_is_valid(buf) then
    -- A session can have its terminal before the view has opened.
    require("dap-view").open()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      if vim.api.nvim_win_get_buf(win) == buf then
        vim.api.nvim_set_current_win(win)
        vim.cmd.startinsert()
        return
      end
    end
  end
  notify("This program has no console. Its output is in the REPL tab (<leader>dr).", vim.log.levels.WARN)
end

function M.debug_this()
  local dap = require("dap")
  if dap.session() then
    dap.continue()
    return
  end
  save()
  local ft = vim.bo.filetype
  if ft == "python" then
    debug_python()
  elseif ft == "c" or ft == "cpp" then
    debug_native()
  elseif ft == "go" then
    debug_go()
  elseif ft == "rust" then
    debug_rust()
  elseif ft == "haskell" or ft == "lhaskell" then
    debug_haskell()
  else
    notify("Don't know how to debug filetype `" .. ft .. "`", vim.log.levels.WARN)
  end
end

return M
