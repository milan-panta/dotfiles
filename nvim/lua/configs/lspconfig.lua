-- declare variable
local mason = require("mason")
local masonLspConfig = require("mason-lspconfig")
local on_attach = require("plugins.lsp").on_attach
local capabilities = require("plugins.lsp").capabilities
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
		on_attach = on_attach,
		capabilities = capabilities,
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
