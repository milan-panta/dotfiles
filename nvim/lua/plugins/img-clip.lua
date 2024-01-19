return {
  "HakonHarnes/img-clip.nvim",
  event = { "BufReadPost", "BufNewFile" },
  opts = {},
  keys = {
    { "<leader>vi", "<cmd>PasteImage<cr>", desc = "Paste clipboard image" },
  },
}
