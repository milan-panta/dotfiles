-- declare variable
local mason = require("mason")
local masonLspConfig = require("mason-lspconfig")
local keymap = vim.keymap

local on_attach = function(_, bufnr)
	local opts = { noremap = true, silent = true }
	opts.buffer = bufnr
	keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
	keymap.set("n", "gd", vim.lsp.buf.definition, opts)
	keymap.set("n", "<Leader>k", vim.lsp.buf.hover, opts)
	keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
	keymap.set("n", "<Leader>lh", vim.lsp.buf.signature_help, opts)
	keymap.set("n", "<Leader>wa", vim.lsp.buf.add_workspace_folder, opts)
	keymap.set("n", "<Leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
	keymap.set("n", "<Leader>D", vim.lsp.buf.type_definition, opts)
	keymap.set("n", "<Leader>rn", vim.lsp.buf.rename, opts)
	keymap.set({ "n", "v" }, "<Leader>la", vim.lsp.buf.code_action, opts)
	keymap.set("n", "gr", vim.lsp.buf.references, opts)
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

		-- rust
		"rust_analyzer",
	},
})

-- default configs for these language servers
local servers = {
	"html",
	"emmet_ls",
	"cssls",
	"rust_analyzer",
	"pyright",
}

-- configure with default lsp settings
for _, lsp in ipairs(servers) do
	lspconfig[lsp].setup({
		capabilities = capabilities,
		on_attach = on_attach,
	})
end

-- manually configure
lspconfig.lua_ls.setup({
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

lspconfig.clangd.setup({
	on_attach = on_attach,
	capabilities = capabilities,
	cmd = {
		"clangd",
		"--offset-encoding=utf-16",
	},
})

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
