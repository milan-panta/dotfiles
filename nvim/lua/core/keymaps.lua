local vim = vim

vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "J", "mzJ`z")
vim.keymap.set("n", "<C-d>", "5<C-d>")
vim.keymap.set("n", "<C-u>", "5<C-u>")

-- Maintain cursor position after yank
vim.keymap.set("v", "y", "ygv<Esc>")
vim.keymap.set("v", "Y", '"*ygv<Esc>')

-- Remove text highlight after search
vim.keymap.set("n", "<Esc>", "<cmd>:noh<CR>", { desc = "Clear Highlights" })

-- Back to back indents
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

vim.keymap.set({ "n", "i" }, "<C-q>", ":q<CR>")

vim.keymap.set("n", "<Leader>s", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]], { desc = "Replace word" })

vim.keymap.set("n", "<Leader>vpp", "<cmd>e ~/.config/nvim/lua/<CR>", { desc = "Open nvim config" })

-- format
function Format()
	-- save
	vim.cmd("silent :w")

	-- default lsp format
	vim.lsp.buf.format()

	-- specify formatter
	local filetype = vim.bo.filetype
	if filetype == "python" then
		vim.cmd("silent !ruff format %")
	end
	vim.cmd("silent :w")
end

-- format + run
function RunFile(dir)
	Format()
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
end, { desc = "Save and run vertically" })

vim.keymap.set("n", "<leader>rh", function()
	RunFile("split")
end, { desc = "Save and run horizontally" })

-- formatting
vim.keymap.set("n", "<leader>lf", Format, { desc = "Save and format" })
