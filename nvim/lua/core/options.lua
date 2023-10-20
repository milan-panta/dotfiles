vim.opt.termguicolors = true
vim.opt.cursorline = true
vim.opt.laststatus = 3 -- global statusline

vim.opt.signcolumn = "number"
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.statuscolumn = "%=%{&nu?(&rnu && v:relnum?v:relnum:v:lnum):''} %C"

vim.opt.guicursor = ""

vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.smartindent = true

vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.undofile = true
vim.opt.undolevels = 1000
vim.opt.undoreload = 10000
