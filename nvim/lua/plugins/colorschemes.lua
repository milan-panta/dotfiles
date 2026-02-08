return {
  {
    "folke/tokyonight.nvim",
    lazy = true,
    opts = { style = "night" },
    config = function(_, opts)
      require("tokyonight").setup(opts)
      vim.cmd.colorscheme("tokyonight")
    end,
  },
  {
    "rose-pine/neovim",
    lazy = false,
    priority = 1000,
    name = "rose-pine",
    config = function()
      vim.cmd.colorscheme("rose-pine")
    end,
  },
  {
    "https://gitlab.com/motaz-shokry/gruvbox.nvim",
    lazy = true,
    name = "gruvbox",
    config = function()
      vim.cmd.colorscheme("gruvbox-hard")
    end,
  },
}
