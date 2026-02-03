return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    -- priority = 1000,
    opts = {
      style = "night",
    },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight-night")
    end,
  },
  {
    "rose-pine/neovim",
    lazy = true,
    -- priority = 1000,
    name = "rose-pine",
    opts = {},
  },
  {
    "https://gitlab.com/motaz-shokry/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    name = "gruvbox",
    priority = 1000,
    config = function()
      vim.cmd("colorscheme gruvbox-hard")
    end,
  },
}
