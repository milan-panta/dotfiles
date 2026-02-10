local map = vim.keymap.set

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

map("n", "<leader>rs", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Search and replace word" })

map("n", "J", "mzJ`z", { desc = "Join lines (keep cursor)" })

map("o", "iq", 'i"', { desc = "Inside quotes" })
map("o", "aq", 'a"', { desc = "Around quotes" })

map("n", "?", "?\\v") -- very magic regex mode by default
map("n", "/", "/\\v")

map("n", "<C-u>", "<C-u>zz")
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-f>", "<C-f>zz")
map("n", "<C-b>", "<C-b>zz")
map("n", "n", "nzz")
map("n", "N", "Nzz")
map("n", "*", "*zz")
map("n", "#", "#zz")
map("n", "g*", "g*zz")

map("v", "y", "ygv<Esc>", { desc = "Yank (keep cursor)" })

map("n", "<BS>", "<C-^>", { silent = true, desc = "Alternate file" })

map("n", "Y", '"+y', { desc = "Yank to system clipboard" })
map("v", "Y", '"+ygv<Esc>', { desc = "Yank to system clipboard" })

map("n", "<Esc>", "<cmd>noh<cr>", { silent = true, desc = "Clear highlights" })

map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

map("n", "<M-Up>", "<cmd>resize +2<cr>", { desc = "Increase Window Height" })
map("n", "<M-Down>", "<cmd>resize -2<cr>", { desc = "Decrease Window Height" })
map("n", "<M-Right>", "<cmd>vertical resize -2<cr>", { desc = "Decrease Window Width" })
map("n", "<M-Left>", "<cmd>vertical resize +2<cr>", { desc = "Increase Window Width" })

local function RunFile(dir, args)
  args = args or ""
  vim.cmd.write()

  local file = vim.api.nvim_buf_get_name(0)
  local file_no_ext = vim.fn.fnamemodify(file, ":r")
  local filetype = vim.bo.filetype
  local cmd = ""

  if filetype == "c" then
    cmd = string.format("gcc -Wall -g -std=gnu99 '%s' -o '%s' && '%s' %s", file, file_no_ext, file_no_ext, args)
  elseif filetype == "cpp" then
    cmd = string.format(
      "g++ -g -std=c++23 -Wall -Wextra -Wpedantic -fsanitize=address,undefined '%s' -o '%s' && '%s' %s",
      file,
      file_no_ext,
      file_no_ext,
      args
    )
  elseif filetype == "python" then
    cmd = string.format("python3 -u '%s' %s", file, args)
  elseif filetype == "rust" then
    if args ~= "" then
      cmd = "cargo run -- " .. args
    else
      cmd = "cargo run"
    end
  elseif filetype == "go" then
    cmd = string.format("go run '%s' %s", file, args)
  elseif filetype == "javascript" then
    cmd = string.format("node '%s' %s", file, args)
  elseif filetype == "typescript" then
    cmd = string.format("npx tsx '%s' %s", file, args)
  else
    vim.notify("Filetype " .. filetype .. " is not supported", vim.log.levels.WARN)
    return
  end

  if not vim.env.TMUX then
    if dir == "vsplit" then
      vim.cmd.vsplit()
    else
      vim.cmd.split()
    end
    vim.cmd.terminal(cmd)
    vim.cmd.startinsert()
    return
  end

  local tmux_split_args = dir == "vsplit" and { "tmux", "split-window", "-h", "-P", "-F", "#{pane_id}" }
    or { "tmux", "split-window", "-v", "-P", "-F", "#{pane_id}" }

  local result = vim.system(tmux_split_args):wait()
  if result.code ~= 0 or not result.stdout or result.stdout == "" then
    vim.notify("Failed to create tmux split", vim.log.levels.ERROR)
    return
  end

  local pane_id = result.stdout:gsub("%s+", "")

  vim.system({ "tmux", "send-keys", "-t", pane_id, cmd, "Enter" })
end

map("n", "<leader>r\\", function()
  vim.ui.input({ prompt = "Args: " }, function(input)
    if input then
      RunFile("vsplit", input)
    end
  end)
end, { silent = true, desc = "Run vertically" })
map("n", "<leader>r-", function()
  vim.ui.input({ prompt = "Args: " }, function(input)
    if input then
      RunFile("split", input)
    end
  end)
end, { silent = true, desc = "Run horizontally" })
