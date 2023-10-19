vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { silent = true })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { silent = true })
vim.keymap.set("n", "<Leader>w", "w<CR>", { silent = true })

vim.keymap.set("n", "J", "mzJ`z")
-- vim.keymap.set("n", "<C-d>", "5<C-d>")
-- vim.keymap.set("n", "<C-u>", "5<C-u>")

-- Maintain cursor position after yank
vim.keymap.set("v", "y", "ygv<Esc>")

vim.keymap.set({ "n", "v" }, "Y", '"+y')

-- Remove text highlight after search
vim.keymap.set("n", "<Esc>", "<cmd>noh<CR>", { silent = true, desc = "Clear Highlights" })

-- Back to back indents
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

vim.keymap.set({ "n", "i" }, "<C-q>", "<cmd>q<CR>", { silent = true })

vim.keymap.set("n", "<Leader>vpp", "<cmd>e ~/.config/nvim/lua/<CR>", { silent = true, desc = "Open nvim config" })

-- For Latex
vim.keymap.set("n", "<Leader>th", "<Cmd>TSBufToggle highlight<CR>", { silent = true, desc = "Toggle TS Highlight" })
vim.keymap.set("n", "<Leader>rz", "<Cmd>!zathura %<.pdf & disown<CR>", { silent = true, desc = "Open pdf in zathura" })

-- run file
function RunFile(dir)
  vim.cmd("silent :w")
  local filetype = vim.bo.filetype
  if filetype == "c" then
    vim.fn.feedkeys(":" .. dir .. " | term gcc -Wall % -o %< && ./%< ")
    return
  end
  vim.cmd(dir)
  if filetype == "python" then
    vim.cmd("term python3 -u % ")
  elseif filetype == "cpp" then
    vim.cmd("term g++ % -o %< && ./%< ")
  elseif filetype == "rust" then
    vim.cmd("term cargo run")
  else
    vim.api.nvim_out_write("Filetype " .. filetype .. " is not supported\n")
  end
end

-- code running
vim.keymap.set("n", "<leader>rv", function()
  RunFile("vsplit")
end, { desc = "Save and run vertically", silent = true })

vim.keymap.set("n", "<leader>rh", function()
  RunFile("split")
end, { desc = "Save and run horizontally", silent = true })
