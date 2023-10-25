return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    options = {
      theme = "nord",
    },
    extensions = {
      "nvim-tree",
    },
  },
}
