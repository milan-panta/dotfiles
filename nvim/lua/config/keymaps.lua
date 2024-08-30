-- better naviation with line wrap on
vim.keymap.set("n", "j", "gj", { silent = true })
vim.keymap.set("n", "k", "gk", { silent = true })

-- better insert mode navigation
vim.keymap.set("i", "<C-e>", "<End>", { desc = "End of line" })
vim.keymap.set("i", "<C-y>", "<Home>", { desc = "Beginning of line" })
vim.keymap.set({ "i", "s", "c" }, "<C-k>", "<Up>", { desc = "Move up" })
vim.keymap.set({ "i", "s", "c" }, "<C-l>", "<Right>", { desc = "Move right" })
vim.keymap.set({ "i", "s", "c" }, "<C-j>", "<Down>", { desc = "Move down" })
vim.keymap.set({ "i", "s", "c" }, "<C-h>", "<Left>", { desc = "Move left" })

-- qflist navigation
vim.keymap.set("n", "[q", "<cmd>cp<cr>", {desc = "Previous item on qf", silent = true})
vim.keymap.set("n", "]q", "<cmd>cn<cr>", {desc = "Next item on qf", silent = true})
vim.keymap.set("n", "[Q", "<cmd>cfirst<cr>", {desc = "First item on qf", silent = true})
vim.keymap.set("n", "]Q", "<cmd>clast<cr>", {desc = "Last item on qf", silent = true})
vim.keymap.set("n", "<Leader>q", "<cmd>copen<cr>", {desc = "Open qf list", silent = true})

-- kitty maps M to Cmmd inside tmux sessions
vim.keymap.set({ "n", "i" }, "<M-a>", "<ESC>ggVG")

-- paste without replacing clipboard
vim.keymap.set("x", "<leader>p", [["_dP]])
vim.keymap.set({ "n", "v" }, "<leader>d", [["_d]])

-- select occurrances of word
vim.keymap.set("n", "<leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]])

-- maintain cursor position after joining
vim.keymap.set("n", "J", "mzJ`z")

vim.keymap.set("o", "ir", "i[")
vim.keymap.set("o", "ar", "a[")
vim.keymap.set("o", "iq", 'i"')
vim.keymap.set("o", "aq", 'a"')

-- Maintain cursor position after yank
vim.keymap.set("v", "y", "ygv<Esc>")

-- +y to copy to system clipboard
vim.keymap.set({ "n", "v" }, "Y", '"+y')

-- Remove text highlight after search
vim.keymap.set("n", "<Esc>", "<cmd>noh<cr>", { silent = true, desc = "Clear highlights" })

-- Back to back indents
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- window management
vim.keymap.set("n", "<M-=>", ":resize -2<cr>", { silent = true, noremap = true, desc = "Increase height" })
vim.keymap.set("n", "<M-->", ":resize +2<cr>", { silent = true, noremap = true, desc = "Decrease height" })
vim.keymap.set("n", "<M-.>", ":vertical resize +2<cr>", { silent = true, noremap = true, desc = "Increase width" })
vim.keymap.set("n", "<M-,>", ":vertical resize -2<cr>", { silent = true, noremap = true, desc = "Decrease width" })

-- Consistent with tmux
vim.api.nvim_set_keymap("n", "<C-w>-", "<C-w>s", { noremap = true, desc = "Create horizontal split" })
vim.api.nvim_set_keymap("n", "<C-w>\\", "<C-w>v", { noremap = true, desc = "Create vertical split" })
vim.api.nvim_set_keymap("n", "<C-w>z", "<C-w>_<C-w>|", { noremap = true, desc = "Max out split" })

-- run file
function RunFile(dir)
  vim.cmd("w")
  local filetype = vim.bo.filetype
  if filetype == "c" then
    vim.fn.feedkeys(":" .. dir .. " | term gcc -Wall -g -std=gnu99 % -o %< && ./%< ")
    return
  end
  vim.cmd(dir)
  if filetype == "cpp" then
    vim.cmd("term g++-14 -std=c++20 -Wall % -o %< && ./%<")
    vim.fn.feedkeys("i")
    return
  elseif filetype == "go" then
    vim.cmd("term go build && ./%<")
    vim.fn.feedkeys("i")
    return
  end
  if filetype == "python" then
    vim.cmd("term python3 -u %")
  elseif filetype == "rust" then
    vim.cmd("term cargo run")
  elseif filetype == "javascript" then
    vim.cmd("term node %")
  else
    vim.api.nvim_out_write("Filetype " .. filetype .. " is not supported\n")
  end
  vim.fn.feedkeys("i")
end

-- code running
vim.keymap.set("n", "<leader>rv", function()
  RunFile("vsplit")
end, { silent = true, desc = "Run vertically" })
vim.keymap.set("n", "<leader>rh", function()
  RunFile("split")
end, { silent = true, desc = "Run horizontally" })

-- markdown preview runner
vim.keymap.set("n", "<Leader>rm", "<Cmd>MarkdownPreviewToggle<cr>")
