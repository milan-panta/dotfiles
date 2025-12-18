vim.opt.termguicolors = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.confirm = true

vim.opt.laststatus = 3

vim.opt.number = true
vim.opt.cursorline = true
vim.opt.relativenumber = true

vim.opt.splitright = true
vim.opt.splitbelow = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smartindent = true
vim.opt.softtabstop = 4

vim.opt.wrap = false
vim.opt.scrolloff = 8

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.hlsearch = false

vim.opt.undofile = true
vim.opt.undolevels = 1000
vim.opt.undoreload = 10000

vim.opt.iskeyword = "@,48-57,_,192-255,-"
vim.opt.updatetime = 50
vim.opt.signcolumn = "yes"

-- folke inspiration
vim.opt.mousescroll = "ver:1,hor:4"
vim.opt.fillchars:append({ eob = " " })

-- Disable unused providers for startup speed
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0

vim.o.timeout = true
vim.o.timeoutlen = 200
