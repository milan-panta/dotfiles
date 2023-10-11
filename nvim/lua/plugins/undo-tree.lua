return {
	"mbbill/undotree",
	event = "VeryLazy",
	keys = {
		{
			"<Leader>u",
			function()
				vim.cmd("UndotreeToggle")
			end,
			desc = "Toggle Undo Tree",
		},
	},
}
