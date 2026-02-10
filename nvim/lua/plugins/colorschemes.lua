return {
  {
    "milan-panta/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("gruvbox")
    end,
  },
  {
    "folke/tokyonight.nvim",
    lazy = true,
  },
  {
    "rose-pine/neovim",
    lazy = true,
    name = "rose-pine",
  },
}
