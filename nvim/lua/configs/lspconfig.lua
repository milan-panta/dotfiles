-- declare variable
local mason = require("mason")
local masonLspConfig = require("mason-lspconfig")
local keymap = vim.keymap
local opts = { noremap = true, silent = true }

local on_attach = function(client, bufnr)
	opts.buffer = bufnr

	-- set keybinds
	opts.desc = "Show LSP references"
	keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts) -- show definition, references

	opts.desc = "Go to declaration"
	keymap.set("n", "gD", vim.lsp.buf.declaration, opts) -- go to declaration

	opts.desc = "Show LSP definitions"
	keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts) -- show lsp definitions

	opts.desc = "Show LSP implementations"
	keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts) -- show lsp implementations

	opts.desc = "Show LSP type definitions"
	keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts) -- show lsp type definitions

	opts.desc = "See available code actions"
	keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts) -- see available code actions, in visual mode will apply to selection

	opts.desc = "Smart rename"
	keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts) -- smart rename

	opts.desc = "Show buffer diagnostics"
	keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts) -- show  diagnostics for file

	opts.desc = "Show line diagnostics"
	keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts) -- show diagnostics for line

	opts.desc = "Go to previous diagnostic"
	keymap.set("n", "[d", vim.diagnostic.goto_prev, opts) -- jump to previous diagnostic in buffer

	opts.desc = "Go to next diagnostic"
	keymap.set("n", "]d", vim.diagnostic.goto_next, opts) -- jump to next diagnostic in buffer

	opts.desc = "Show documentation for what is under cursor"
	keymap.set("n", "K", vim.lsp.buf.hover, opts) -- show documentation for what is under cursor

	opts.desc = "Restart LSP"
	keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts) -- mapping to restart lsp if necessary
end

local capabilities = require("cmp_nvim_lsp").default_capabilities()
local lspconfig = require("lspconfig")

mason.setup({
	ui = {
		border = "rounded",
		icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗",
		},
	},
})

-- lsps
masonLspConfig.setup({
	ensure_installed = {
		-- lua
		"lua_ls",

		-- web dev
		"emmet_ls",
		"cssls",
		"html",

		-- c/cpp
		"clangd",

		-- python
		"pyright",
	},
})

-- default configs for these language servers
local servers = {
	"html",
	"emmet_ls",
	"cssls",
	"lua_ls",
	"rust_analyzer",
	"pyright",
	"clangd",
}

-- configure with default lsp settings
for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup({
		capabilities = capabilities,
        on_attach = on_attach,
	})
end

-- manually configure
lspconfig["lua_ls"].setup({
	on_atach = on_attach,
	capabilities = capabilities,
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim", "bufnr" },
			},
		},
	},
})

-- lspconfig["pyright"].setup({
-- 	on_attach = on_attach,
-- 	capabilities = capabilities,
-- 	settings = {
-- 		python = {
-- 			autoSearchPaths = true,
-- 			useLibraryCodeForTypes = true,
-- 			diagnosticMode = "openFilesOnly",
-- 		},
-- 	},
-- 	handlers = {
-- 		["textDocument/publishDiagnostics"] = function() end,
-- 	},
-- })

-- debuggers
require("mason-nvim-dap").setup({
	ensure_installed = { "debugpy" },
})

-- null_ls linters + formatters
require("mason-null-ls").setup({
	ensure_installed = {
		"stylua",
		"ruff",
		"prettier",
		"clangd",
		"clang-format",
	},
})

local null_ls = require("null-ls")

local b = null_ls.builtins

local sources = {

	-- lua
	b.formatting.stylua,

	-- web dev
	b.formatting.prettier.with({ filetypes = { "html", "css", "markdown" } }), -- only use prettier for these

	-- python
	-- uses ${config_dir}/ruff/pyproject.toml settings unless specified in project
	-- for me that is ~/Library/Application\ Support/ruff
	b.diagnostics.ruff,
	b.formatting.ruff,

	-- cpp
	b.formatting.clang_format,
}

null_ls.setup({
	debug = true,
	sources = sources,
})
