local map = vim.keymap.set

-- Neovim's default LSP maps are global and all start with gr, so Snacks' gr (references)
-- would have to wait for them. cd (rename), g. (code action), gd/gI/gy and <leader>cc
-- (codelens) cover them.
for _, lhs in ipairs({ "grn", "grr", "gri", "grt", "grx" }) do
  pcall(vim.keymap.del, "n", lhs)
end
pcall(vim.keymap.del, { "n", "x" }, "gra")

map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { desc = "Down", expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { desc = "Up", expr = true, silent = true })

map("n", "<C-q>", function()
  local qf_exists = false
  for _, win in ipairs(vim.fn.getwininfo()) do
    if win.quickfix == 1 then
      qf_exists = true
      break
    end
  end
  if qf_exists then
    vim.cmd.cclose()
  else
    vim.cmd.copen()
  end
end, { desc = "Toggle quickfix", silent = true })

map("x", "<leader>p", [["_dP]], { desc = "Paste without replacing clipboard" })
map({ "n", "v" }, "<leader>x", [["_d]], { desc = "Delete without copying" })

map("n", "<leader>sR", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace Word in File" })

map("n", "J", "mzJ`z", { desc = "Join lines (keep cursor)" })

map("o", "iq", 'i"', { desc = "Inside quotes" })
map("o", "aq", 'a"', { desc = "Around quotes" })

map("n", "<C-w>-", "<C-w>s", { desc = "Split horizontally" })
map("n", "<C-w>\\", "<C-w>v", { desc = "Split vertically" })

-- Scrolling and searching keep the cursor line centred.
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down" })
map("n", "<C-f>", "<C-f>zz", { desc = "Page down" })
map("n", "<C-b>", "<C-b>zz", { desc = "Page up" })
map("n", "n", "nzz", { desc = "Next match" })
map("n", "N", "Nzz", { desc = "Previous match" })
map("n", "*", "*zz", { desc = "Search word forward" })
map("n", "#", "#zz", { desc = "Search word backward" })
map("n", "g*", "g*zz", { desc = "Search partial word forward" })

map("v", "y", "ygv<Esc>", { desc = "Yank (keep cursor)" })

map("n", "<BS>", "<C-^>", { silent = true, desc = "Alternate file" })

map("n", "Y", '"+y', { desc = "Yank to system clipboard" })
map("v", "Y", '"+ygv<Esc>', { desc = "Yank to system clipboard" })

map("n", "<Esc>", "<cmd>noh<cr>", { silent = true, desc = "Clear highlights" })

map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

for _, key in ipairs({ "<LeftMouse>", "<RightMouse>" }) do
  map("n", key, function()
    return require("config.breakpoints").gutter_click(key)
  end, { expr = true, desc = "Gutter: run test or toggle breakpoint" })
end

-- Alt+Shift+h/j/k/l moves the split border that way, the same keys tmux uses for panes.
-- With no Neovim split that way, it resizes the tmux pane instead (tmux.conf hands these keys
-- to Neovim). Alt+h/j/k/l, without Shift, moves between splits and panes.
local function resize(dir)
  local horizontal = dir == "Left" or dir == "Right"
  local after, before = horizontal and "l" or "j", horizontal and "h" or "k"
  local grow = dir == "Right" or dir == "Down"
  local cmd = horizontal and "vertical resize " or "resize "
  if vim.fn.winnr(after) ~= vim.fn.winnr() then
    vim.cmd(cmd .. (grow and "+2" or "-2"))
  elseif vim.fn.winnr(before) ~= vim.fn.winnr() then
    vim.cmd(cmd .. (grow and "-2" or "+2"))
  elseif vim.env.TMUX then
    vim.system({ "tmux", "resize-pane", "-" .. dir:sub(1, 1), "5" })
  end
end
for key, dir in pairs({ H = "Left", J = "Down", K = "Up", L = "Right" }) do
  map("n", "<M-" .. key .. ">", function()
    resize(dir)
  end, { desc = "Move split border " .. dir:lower() })
end

local output_pane_id = nil
local cpu_count = tostring(#vim.uv.cpu_info())

local function tmux_pane_exists(pane_id)
  if not pane_id then
    return false
  end
  local result = vim.system({ "tmux", "display-message", "-p", "-t", pane_id, "#{pane_dead}" }):wait()
  return result.code == 0 and result.stdout and vim.trim(result.stdout) == "0"
end

-- Run cmd in a tmux pane split to the right of Neovim. The pane is reused (interrupting whatever
-- it was running) until closed, even after being moved to another window.
local function run_in_pane(cmd)
  if not vim.env.TMUX then
    vim.cmd("botright vsplit")
    vim.cmd.terminal(cmd)
    vim.cmd.startinsert()
    return
  end

  if tmux_pane_exists(output_pane_id) then
    vim.system({ "tmux", "send-keys", "-t", output_pane_id, "C-c" }):wait()
    vim.system({ "tmux", "send-keys", "-t", output_pane_id, cmd, "Enter" })
    return
  end

  local split = { "tmux", "split-window", "-h", "-d", "-l", "40%", "-P", "-F", "#{pane_id}", "-c", vim.fn.getcwd() }
  if vim.env.TMUX_PANE then
    vim.list_extend(split, { "-t", vim.env.TMUX_PANE })
  end
  local result = vim.system(split):wait()
  if result.code ~= 0 or not result.stdout or result.stdout == "" then
    vim.notify("Failed to create tmux pane", vim.log.levels.ERROR)
    return
  end

  output_pane_id = vim.trim(result.stdout)
  vim.system({ "tmux", "send-keys", "-t", output_pane_id, cmd, "Enter" })
end

local function RunFile(args, mode)
  args = args or ""
  mode = mode or "debug"
  vim.cmd.write()

  local file = vim.api.nvim_buf_get_name(0)
  local file_no_ext = vim.fn.fnamemodify(file, ":r")
  local filetype = vim.bo.filetype
  local cmd = ""
  local escaped_file = vim.fn.shellescape(file)

  if filetype == "c" then
    local flags = mode == "release" and "-O3 -std=gnu99" or "-Wall -g -std=gnu99"
    local out = mode == "release" and (file_no_ext .. "_release") or file_no_ext
    local escaped_out = vim.fn.shellescape(out)
    cmd = string.format("gcc %s %s -o %s && %s %s", flags, escaped_file, escaped_out, escaped_out, args)
  elseif filetype == "cpp" then
    local flags = mode == "release" and "-O3 -std=c++23" or "-g -std=c++23 -Wall -Wextra -Wpedantic"
    local out = mode == "release" and (file_no_ext .. "_release") or file_no_ext
    local escaped_out = vim.fn.shellescape(out)
    cmd = string.format("g++ %s %s -o %s && %s %s", flags, escaped_file, escaped_out, escaped_out, args)
  elseif filetype == "python" then
    -- The project's venv, so its dependencies import.
    local python = vim.fn.shellescape(require("config.debug").python_for(file))
    cmd = string.format("%s -u %s %s", python, escaped_file, args)
  elseif filetype == "rust" then
    local release_flag = mode == "release" and " --release" or ""
    -- From the crate root, so it works when Neovim started in a parent folder.
    local crate = vim.fs.root(file, "Cargo.toml") or vim.fs.dirname(file)
    cmd = "cd "
      .. vim.fn.shellescape(crate)
      .. " && cargo run"
      .. release_flag
      .. (args ~= "" and (" -- " .. args) or "")
  elseif filetype == "go" then
    -- The whole package: one file of it can't see the others' functions.
    cmd = string.format("cd %s && go run . %s", vim.fn.shellescape(vim.fs.dirname(file)), args)
  elseif filetype == "haskell" or filetype == "lhaskell" then
    local ghci = vim.fn.shellescape(vim.fn.expand("~/.ghcup/bin/ghci"))
    cmd = string.format("%s %s", ghci, escaped_file)
  elseif filetype == "javascript" then
    cmd = string.format("node %s %s", escaped_file, args)
  elseif filetype == "typescript" then
    cmd = string.format("npx tsx %s %s", escaped_file, args)
  else
    vim.notify("Filetype " .. filetype .. " is not supported", vim.log.levels.WARN)
    return
  end

  run_in_pane(cmd)
end

map("n", "<leader>rr", function()
  RunFile()
end, { silent = true, desc = "Run file" })

local function RunFileWithArgs(mode)
  if vim.bo.filetype == "haskell" or vim.bo.filetype == "lhaskell" then
    RunFile()
    return
  end
  vim.ui.input({ prompt = "Args: " }, function(input)
    if input ~= nil then
      RunFile(input, mode)
    end
  end)
end

map("n", "<leader>ra", function()
  RunFileWithArgs()
end, { silent = true, desc = "Run file (args)" })

map("n", "<leader>ro", function()
  RunFileWithArgs("release")
end, { silent = true, desc = "Run file optimized (args)" })

-- Build System Keymaps
map("n", "<leader>bn", function()
  run_in_pane("ninja -C build")
end, { desc = "Ninja build" })

map("n", "<leader>bp", function()
  local cmd, name = require("config.build").build_shell_command()
  if not cmd then
    vim.notify("No CMake, Meson, Make, or Ninja project found", vim.log.levels.WARN)
    return
  end
  vim.notify("Building with " .. name, vim.log.levels.INFO)
  run_in_pane(cmd)
end, { desc = "Build project (auto)" })

-- Copy file:line to system clipboard
map("n", "<leader>y", function()
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
  local line = vim.fn.line(".")
  local loc = path .. ":" .. line
  vim.fn.setreg("+", loc)
  vim.notify(loc, vim.log.levels.INFO)
end, { desc = "Copy file:line" })

map("v", "<leader>y", function()
  local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":~:.")
  local start_line = vim.fn.line("v")
  local end_line = vim.fn.line(".")
  if start_line > end_line then
    start_line, end_line = end_line, start_line
  end
  local loc = start_line == end_line and path .. ":" .. start_line or path .. ":" .. start_line .. "-" .. end_line
  vim.fn.setreg("+", loc)
  vim.notify(loc, vim.log.levels.INFO)
end, { desc = "Copy file:line range" })

-- CMake build
map("n", "<leader>bc", function()
  run_in_pane("cmake --build build -j" .. cpu_count)
end, { silent = true, desc = "CMake build" })

-- Bazel build
map("n", "<leader>bb", function()
  run_in_pane("bazel build //...")
end, { silent = true, desc = "Bazel Build All" })

map("n", "<leader>bt", function()
  run_in_pane("bazel test //...")
end, { silent = true, desc = "Bazel Test All" })
