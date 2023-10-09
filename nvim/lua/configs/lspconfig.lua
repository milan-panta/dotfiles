-- declare variable
local mason = require("mason")
local masonLspConfig = require("mason-lspconfig")
local keymap = vim.keymap

local on_attach = function(_, bufnr)
	local opts = { noremap = true, silent = true }
	opts.buffer = bufnr
	keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
	keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
	keymap.set("n", "gD", "<cmd>Telescope lsp_type_definitions<CR>", opts)
	keymap.set("n", "gI", "<cmd>Telescope lsp_implementations<CR>", opts)
	keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)
	keymap.set("n", "gl", vim.diagnostic.open_float, opts)
	keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
	keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
	keymap.set("n", "<leader>lk", vim.lsp.buf.hover, opts)
	keymap.set("n", "<leader>la", vim.lsp.buf.code_action, opts)
	keymap.set("n", "<leader>lr", vim.lsp.buf.rename, opts)
	keymap.set("n", "<leader>ls", vim.lsp.buf.signature_help, opts)
	keymap.set("n", "<leader>li", vim.cmd.LspInfo, opts)
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
		"denols",

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
	capabilities = capabilities,
	settings = {
		Lua = {
			diagnostics = {
				globals = { "vim", "bufnr" },
			},
		},
	},
	on_attach = on_attach,
})

lspconfig.clangd.setup({
	on_attach = on_attach,
	capabilities = capabilities,
	cmd = {
		"clangd",
		"--offset-encoding=utf-16",
	},
})

-- debugging
require("mason-nvim-dap").setup({
	ensure_installed = { "debugpy" },
})

-- installing linters and formatters
require("mason-tool-installer").setup({
	ensure_installed = {
		"stylua",
		"clang-format",
		"prettierd",
		"ruff",
	},
	auto_update = true,
})

-- formatting with conform
local conform = require("conform")
conform.setup({
	formatters_by_ft = {
		c = { "clang_format" },
		lua = { "stylua" },
		python = { "ruff_fix", "ruff_format" },
		markdown = { "prettierd" },
		javascript = { "prettierd" },
		javascriptreact = {},
		typescript = { "prettierd" },
		typescriptreact = {},
	},
	formatters = {
		dprint = {
			condition = function(ctx)
				return vim.fs.find({ "dprint.json" }, { path = ctx.filename, upward = true })[1]
			end,
		},
	},
})

vim.keymap.set({ "n", "v" }, "<Leader>lf", function()
	conform.format({
		lsp_fallback = true,
		async = false,
		timeout_ms = 1000,
	})
	vim.cmd("silent :w")
end, { desc = "Format file or range (in visual mode)" })

-- linting with nvim-lint
local lint = require("lint")

lint.linters_by_ft = {
	python = { "ruff" },
}

vim.api.nvim_create_autocmd({ "TextChanged", "BufWinEnter" }, {
	callback = function()
		require("lint").try_lint()
	end,
})
