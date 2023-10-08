return {
	"neovim/nvim-lspconfig",
	event = "VeryLazy",
	dependencies = {
		{
			"williamboman/mason.nvim",
			event = "VeryLazy",
		},
		{
			"williamboman/mason-lspconfig.nvim",
			event = { "BufReadPre", "BufNewFile" },
		},
		{
			"hrsh7th/cmp-nvim-lsp",
			event = { "BufReadPre", "BufNewFile" },
		},
		{
			"mfussenegger/nvim-dap",
			event = { "BufReadPre", "BufNewFile" },
		},
		{
			"jay-babu/mason-nvim-dap.nvim",
			event = { "BufReadPre", "BufNewFile" },
		},
		{
			"stevearc/conform.nvim",
			event = { "BufReadPre", "BufNewFile" },
		},
		{
			"mfussenegger/nvim-lint",
			event = { "BufReadPre", "BufNewFile" },
		},
	},
	config = function()
		require("configs.lspconfig")
	end,
}
