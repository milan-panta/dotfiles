return {
	{
		"neovim/nvim-lspconfig",
		event = "VeryLazy",
		dependencies = {
			{
				"williamboman/mason.nvim",
				event = "VeryLazy",
			},
			{
				"jay-babu/mason-null-ls.nvim",
				event = { "BufReadPre", "BufNewFile" },
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
				"nvimtools/none-ls.nvim",
				event = "VeryLazy",
			},
		},
		config = function()
			require("configs.lspconfig")
		end,
	},
}
