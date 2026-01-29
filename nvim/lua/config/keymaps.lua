-- Global keymaps (plugin-specific live with their plugins)

local map = vim.keymap.set

-- Navigation

-- Better navigation with line wrap
map("n", "j", "gj", { silent = true, desc = "Move down (wrap-aware)" })
map("n", "k", "gk", { silent = true, desc = "Move up (wrap-aware)" })

-- qflist navigation
map("n", "<leader>Tq", "<cmd>copen<cr>", { desc = "Toggle qf list", silent = true })

-- save file
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })

-- paste without replacing clipboard
map("x", "<leader>p", [["_dP]], { desc = "Paste without replacing clipboard" })
map({ "n", "v" }, "<leader>x", [["_d]], { desc = "Delete without copying" })

-- select occurrances of word
map("n", "<leader>rs", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Search and replace word" })

-- maintain cursor position after joining
map("n", "J", "mzJ`z", { desc = "Join lines (keep cursor)" })

map("o", "iq", 'i"', { desc = "Inside quotes" })
map("o", "aq", 'a"', { desc = "Around quotes" })

-- "very magic" (less escaping needed) regexes by default
map("n", "?", "?\\v")
map("n", "/", "/\\v")

-- center the file after common movements
map("n", "<C-u>", "<C-u>zz")
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-f>", "<C-f>zz")
map("n", "<C-b>", "<C-b>zz")
map("n", "n", "nzz")
map("n", "N", "Nzz")
map("n", "*", "*zz")
map("n", "#", "#zz")
map("n", "g*", "g*zz")

-- Maintain cursor position after yank
map("v", "y", "ygv<Esc>", { desc = "Yank (keep cursor)" })

-- switch between most recent files
map("n", "<BS>", "<C-^>", { silent = true, desc = "Alternate file" })

-- +y to copy to system clipboard
map("n", "Y", '"+y', { desc = "Yank to system clipboard" })
map("v", "Y", '"+ygv<Esc>', { desc = "Yank to system clipboard" })

-- Remove text highlight after search
map("n", "<Esc>", "<cmd>noh<cr>", { silent = true, desc = "Clear highlights" })

-- Back to back indents
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

-- window management
map("n", "<M-=>", ":resize +2<cr>", { silent = true, desc = "Increase height" })
map("n", "<M-->", ":resize -2<cr>", { silent = true, desc = "Decrease height" })
map("n", "<M-.>", ":vertical resize +2<cr>", { silent = true, desc = "Increase width" })
map("n", "<M-,>", ":vertical resize -2<cr>", { silent = true, desc = "Decrease width" })

-- Consistent with tmux
map("n", "<C-w>z", "<C-w>_<C-w>|", { desc = "Max out split" })

-- run file
local function RunFile(dir, args)
  args = args or ""
  vim.cmd("w")

  local file = vim.fn.expand("%:p")
  local file_no_ext = vim.fn.expand("%:p:r")
  local filetype = vim.bo.filetype
  local cmd = ""

  if filetype == "c" then
    cmd = string.format("gcc -Wall -g -std=gnu99 '%s' -o '%s' && '%s' %s", file, file_no_ext, file_no_ext, args)
  elseif filetype == "cpp" then
    cmd = string.format("g++-15 -g -std=c++23 -Wall '%s' -o '%s' && '%s' %s", file, file_no_ext, file_no_ext, args)
  elseif filetype == "python" then
    cmd = string.format("python3 -u '%s' %s", file, args)
  elseif filetype == "rust" then
    if args ~= "" then
      cmd = "cargo run -- " .. args
    else
      cmd = "cargo run"
    end
  elseif filetype == "javascript" then
    cmd = string.format("node '%s' %s", file, args)
  elseif filetype == "typescript" then
    cmd = string.format("npx tsx '%s' %s", file, args)
  else
    vim.notify("Filetype " .. filetype .. " is not supported", vim.log.levels.WARN)
    return
  end

  -- Fallback to standard terminal if not in tmux
  if not vim.env.TMUX then
    if dir == "vsplit" then
      vim.cmd("vsplit")
    else
      vim.cmd("split")
    end
    vim.cmd("term " .. cmd)
    vim.cmd("startinsert")
    return
  end

  local tmux_split_cmd = ""
  if dir == "vsplit" then
    tmux_split_cmd = "tmux split-window -h -P -F '#{pane_id}'"
  else
    tmux_split_cmd = "tmux split-window -v -P -F '#{pane_id}'"
  end

  local handle = io.popen(tmux_split_cmd)
  if not handle then
    vim.notify("Failed to create tmux split", vim.log.levels.ERROR)
    return
  end
  local pane_id = handle:read("*a")
  handle:close()

  if not pane_id or pane_id == "" then
    vim.notify("Failed to get tmux pane id", vim.log.levels.ERROR)
    return
  end

  pane_id = pane_id:gsub("%s+", "")

  local clean_cmd = cmd:gsub('"', '\\"')
  local send_keys_cmd = string.format('tmux send-keys -t %s "%s" Enter', pane_id, clean_cmd)

  os.execute(send_keys_cmd)
end

-- code running
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
