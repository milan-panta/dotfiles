return {
  -- catppuccin
  {
    "catppuccin/nvim",
    lazy = true,
    -- priority = 1000,
    config = function()
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  -- gruvbox
  {
    lazy = true,
    -- priority = 1000,
    "ellisonleao/gruvbox.nvim",
    config = function()
      vim.cmd.colorscheme("gruvbox")
    end,
  },
  -- kanagawa
  {
    -- lazy = true,
    priority = 1000,
    "rebelot/kanagawa.nvim",
    config = function()
      vim.cmd.colorscheme("kanagawa-dragon")
    end,
  },
}
