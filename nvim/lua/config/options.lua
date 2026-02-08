local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.laststatus = 3
opt.showmode = false
opt.scrolloff = 8
opt.wrap = false
opt.fillchars:append({ eob = " " })
opt.mousescroll = "ver:1,hor:4"

opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undolevels = 1000
opt.undoreload = 10000
opt.confirm = true

opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen"

opt.jumpoptions = "view"

opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

opt.updatetime = 100

opt.diffopt:append("iwhite")
opt.diffopt:append("algorithm:histogram")
opt.diffopt:append("indent-heuristic")

vim.o.timeout = true
vim.o.timeoutlen = 200

opt.pumheight = 10
opt.completeopt = "menu,menuone,noselect"

vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
