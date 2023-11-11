vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true })

-- better insert mode navigation
vim.keymap.set("i", "<C-b>", "<ESC>^i", { desc = "Beginning of line" })
vim.keymap.set("i", "<C-e>", "<End>", { desc = "End of line" })
vim.keymap.set({ "i", "s", "c" }, "<C-h>", "<Left>", { desc = "Move left" })
vim.keymap.set({ "i", "s", "c" }, "<C-l>", "<Right>", { desc = "Move right" })

-- kitty maps Cmmd to M inside tmux sessions
vim.keymap.set({ "n", "i" }, "<M-a>", "<ESC>ggVG")
vim.keymap.set({ "n" }, "<M-s>", "<cmd>silent w<CR>")
vim.keymap.set({ "i" }, "<M-s>", "<ESC><cmd>silent w<CR>a")

-- maintain cursor position after joining
vim.keymap.set("n", "J", "mzJ`z")

vim.keymap.set("o", "ir", "i[")
vim.keymap.set("o", "ar", "a[")

-- Maintain cursor position after yank
vim.keymap.set("v", "y", "ygv<Esc>")

vim.keymap.set({ "n", "v" }, "Y", '"+y')

-- Remove text highlight after search
vim.keymap.set("n", "<Esc>", "<cmd>noh<CR>", { silent = true, desc = "Clear highlights" })

-- Back to back indents
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Fix navigation for line wraps
vim.keymap.set({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
vim.keymap.set({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- For Latex
vim.keymap.set("n", "<Leader>th", "<Cmd>TSBufToggle highlight<CR>", { silent = true, desc = "Toggle TS Highlight" })

-- window management
vim.api.nvim_set_keymap("n", "<C-a>", "<C-w>>", { noremap = true, desc = "Increase width" })
vim.api.nvim_set_keymap("n", "<C-f>", "<C-w><", { noremap = true, desc = "Decrease width" })
vim.api.nvim_set_keymap("n", "<C-s>", "<C-w>+", { noremap = true, desc = "Decrease height" })
vim.api.nvim_set_keymap("n", "<C-w>-", "<C-w>s", { noremap = true, desc = "Create vertical split" })
vim.api.nvim_set_keymap("n", "<C-w>\\", "<C-w>v", { noremap = true, desc = "Create vertical split" })
vim.api.nvim_set_keymap("n", "<C-w>z", "<C-w>_<C-w>|", { noremap = true, desc = "Max out split" })

-- run file
function RunFile(dir)
  vim.cmd("silent :w")
  local filetype = vim.bo.filetype
  if filetype == "c" then
    vim.fn.feedkeys(":" .. dir .. " | term gcc -Wall % -o %< && ./%<\ni")
    return
  elseif filetype == "cpp" then
    vim.fn.feedkeys(":" .. dir .. " | term g++ -Wall % -o %< && ./%<\ni")
    return
  end
  vim.cmd(dir)
  vim.fn.feedkeys(":term ")
  if filetype == "python" then
    vim.fn.feedkeys("python3 -u %")
  elseif filetype == "rust" then
    vim.fn.feedkeys("cargo run")
  elseif filetype == "javascript" then
    vim.fn.feedkeys("node %")
  else
    vim.api.nvim_out_write("Filetype " .. filetype .. " is not supported\n")
  end
  vim.fn.feedkeys(" \ni")
end

-- code running
vim.keymap.set("n", "<leader>rv", function()
  RunFile("vsplit")
end, { desc = "Save and run vertically", silent = true })
vim.keymap.set("n", "<leader>rh", function()
  RunFile("split")
end, { desc = "Save and run horizontally", silent = true })
vim.keymap.set("n", "<Leader>rz", "<Cmd>!zathura %<.pdf & disown<CR>", { silent = true, desc = "Open pdf in zathura" })
