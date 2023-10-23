return {
  "nvim-lualine/lualine.nvim",
  event = "UIEnter",
  dependencies = "nvim-tree/nvim-web-devicons",
  opts = {
    options = {
      disabled_filetypes = {
        "dashboard",
      },
      theme = "nord",
    },
  },
}
