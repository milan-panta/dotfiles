local opt = vim.opt

-- UI
opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.laststatus = 3 -- Global statusline
opt.showmode = false -- Mode shown in statusline
opt.scrolloff = 8
opt.wrap = false
opt.fillchars:append({ eob = " " }) -- remove welcome message
opt.mousescroll = "ver:1,hor:4"

-- Files & Persistence
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undolevels = 1000
opt.undoreload = 10000
opt.confirm = true -- Confirm unsaved changes

-- Splits
opt.splitright = true
opt.splitbelow = true

-- Indentation
opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- Editing
opt.iskeyword = "@,48-57,_,192-255,-"
opt.updatetime = 100

-- Diff
opt.diffopt:append("iwhite")
opt.diffopt:append("algorithm:histogram")
opt.diffopt:append("indent-heuristic")

-- Timeout (whichkey and gitsigns)
vim.o.timeout = true
vim.o.timeoutlen = 200

-- Disable unused providers for startup speed
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
