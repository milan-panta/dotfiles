return {
	"nvim-lualine/lualine.nvim",
	priority = 800,

	config = function()
		require("lualine").setup({
			options = {
				theme = "catppuccin",
			},
		})
	end,
}
