return {
  {
    "f4z3r/gruvbox-material.nvim",
    lazy = true,
    priority = 1000,
    name = "gruvbox-material",
    config = function()
      vim.cmd("colorscheme gruvbox-material")
    end,
  },
  {
    "folke/tokyonight.nvim",
    lazy = true,
    priority = 1000,
    opts = {},
    config = function()
      vim.cmd("colorscheme tokyonight-night")
    end,
  },
  {
    "rose-pine/neovim",
    lazy = false,
    priority = 1000,
    name = "rose-pine",
    config = function()
      vim.cmd("colorscheme rose-pine")
    end,
  },
}
