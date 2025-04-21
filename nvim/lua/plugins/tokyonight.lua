return {
  "folke/tokyonight.nvim",
  lazy = true,
  priority = 1000,
  opts = {},
  config = function()
      vim.cmd("colorscheme tokyonight-night")
  end
}
