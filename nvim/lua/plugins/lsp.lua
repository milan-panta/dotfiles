return {
	{
		"neovim/nvim-lspconfig",
		event = {"BufReadPre", "BufNewFile"},
		dependencies = {
			{ "jay-babu/mason-null-ls.nvim" },
			{
				"williamboman/mason.nvim",
				build = function()
					pcall(vim.cmd, "MasonUpdate")
				end,
				keys = {
					{
						"spacem",
						function()
							require("mason.ui").open()
						end,
						desc = "Mason",
					},
				},
			},
			{ "williamboman/mason-lspconfig.nvim" },
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "mfussenegger/nvim-dap" },
			{ "jay-babu/mason-nvim-dap.nvim" },
			{
				"nvimtools/none-ls.nvim",
				event = { "BufReadPre", "BufNewFile" },
			},
		},
		config = function()
			require("configs.lspconfig")
		end,
	},
}
