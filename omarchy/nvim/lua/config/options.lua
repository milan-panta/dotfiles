require("config.remote_clipboard").setup()
local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.laststatus = 3 -- single global statusline for all splits
opt.showmode = false
opt.scrolloff = 8
opt.wrap = false
opt.fillchars:append({ eob = " " }) -- hide ~ after end of buffer
opt.mousescroll = "ver:1,hor:4"
opt.colorcolumn = "120" -- ruff and stylua line length

opt.autoread = true
opt.swapfile = false
opt.backup = false
opt.undofile = true
opt.undolevels = 1000
opt.undoreload = 10000
opt.confirm = true
opt.exrc = true -- load a project's .nvim.lua, after a one-time :trust prompt

opt.splitright = true
opt.splitbelow = true
opt.splitkeep = "screen" -- keep text stable when opening splits

opt.jumpoptions = "view" -- restore view on jumplist navigation

opt.expandtab = true
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.smartindent = true

-- Built-in Python indent: one level inside brackets (ruff/black style, not 2)
vim.g.python_indent = {
  open_paren = "shiftwidth()",
  continue = "shiftwidth()",
  closed_paren_align_last_line = false,
}

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

opt.updatetime = 100 -- faster CursorHold events (gitsigns, lsp)

opt.synmaxcol = 250 -- prevent lag on very long lines
opt.smoothscroll = false

-- treesitter-based folding
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldtext = ""

opt.diffopt:append("iwhite")
opt.diffopt:append("algorithm:histogram")
opt.diffopt:append("indent-heuristic")

opt.timeout = true
opt.timeoutlen = 200

-- One border style for floats you read (hover, signature, diagnostics, pickers, inputs).
-- The completion menu stays flat, like the built-in popup menu (blink-cmp.lua).
opt.winborder = "rounded"

opt.pumheight = 10
opt.completeopt = "menu,menuone,noselect"

-- disable unused providers for startup speed
vim.g.loaded_python3_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
