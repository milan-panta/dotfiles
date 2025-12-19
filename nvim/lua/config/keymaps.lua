-- better naviation with line wrap on
vim.keymap.set("n", "j", "gj", { silent = true, desc = "Move down (wrap-aware)" })
vim.keymap.set("n", "k", "gk", { silent = true, desc = "Move up (wrap-aware)" })

-- qflist navigation
vim.keymap.set("n", "<leader>Tq", "<cmd>copen<cr>", { desc = "Toggle qf list", silent = true })

-- save file
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })

-- kitty maps M to Cmmd inside tmux sessions
vim.keymap.set({ "n", "i" }, "<M-a>", "<ESC>ggVG", { desc = "Select all" })

-- paste without replacing clipboard
vim.keymap.set("x", "<leader>p", [["_dP]], { desc = "Paste without replacing clipboard" })
vim.keymap.set({ "n", "v" }, "<leader>x", [["_d]], { desc = "Delete without copying" })

-- select occurrances of word
vim.keymap.set("n", "<leader>rs", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Search and replace word" })

-- maintain cursor position after joining
vim.keymap.set("n", "J", "mzJ`z", { desc = "Join lines (keep cursor)" })

vim.keymap.set("o", "iq", 'i"', { desc = "Inside quotes" })
vim.keymap.set("o", "aq", 'a"', { desc = "Around quotes" })

-- Maintain cursor position after yank
vim.keymap.set("v", "y", "ygv<Esc>", { desc = "Yank (keep cursor)" })

-- +y to copy to system clipboard
vim.keymap.set({ "n", "v" }, "Y", '"+y', { desc = "Yank to system clipboard" })

-- Remove text highlight after search
vim.keymap.set("n", "<Esc>", "<cmd>noh<cr>", { silent = true, desc = "Clear highlights" })

-- Back to back indents
vim.keymap.set("v", "<", "<gv", { desc = "Indent left" })
vim.keymap.set("v", ">", ">gv", { desc = "Indent right" })

-- window management
vim.keymap.set("n", "<M-=>", ":resize +2<cr>", { silent = true, desc = "Increase height" })
vim.keymap.set("n", "<M-->", ":resize -2<cr>", { silent = true, desc = "Decrease height" })
vim.keymap.set("n", "<M-.>", ":vertical resize +2<cr>", { silent = true, desc = "Increase width" })
vim.keymap.set("n", "<M-,>", ":vertical resize -2<cr>", { silent = true, desc = "Decrease width" })

-- Consistent with tmux
vim.keymap.set("n", "<C-w>-", "<C-w>s", { desc = "Create horizontal split" })
vim.keymap.set("n", "<C-w>\\", "<C-w>v", { desc = "Create vertical split" })
vim.keymap.set("n", "<C-w>z", "<C-w>_<C-w>|", { desc = "Max out split" })

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
vim.keymap.set("n", "<leader>r\\", function()
  vim.ui.input({ prompt = "Args: " }, function(input)
    if input then
      RunFile("vsplit", input)
    end
  end)
end, { silent = true, desc = "Run vertically" })
vim.keymap.set("n", "<leader>r-", function()
  vim.ui.input({ prompt = "Args: " }, function(input)
    if input then
      RunFile("split", input)
    end
  end)
end, { silent = true, desc = "Run horizontally" })

-- markdown preview runner
vim.keymap.set("n", "<leader>rm", "<Cmd>MarkdownPreviewToggle<cr>", { desc = "Markdown preview" })
