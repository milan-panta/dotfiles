return {
  "nvim-lualine/lualine.nvim",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = "nvim-tree/nvim-web-devicons",
  opts = {
    options = {
      theme = "nord",
    },
    extensions = {
      "nvim-tree",
    },
  },
}
