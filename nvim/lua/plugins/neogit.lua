return {
  "NeogitOrg/neogit",
  lazy = true,
  cmd = "Neogit",
  dependencies = {
    "nvim-lua/plenary.nvim", -- required
    "sindrets/diffview.nvim", -- optional - Diff integration
  },
  config = true,
  keys = {
    { "<leader>gg", "<cmd>Neogit<cr>", desc = "Neogit Status" },
    { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit Commit" },
    { "<leader>gP", "<cmd>Neogit push<cr>", desc = "Neogit Push" },
    { "<leader>gp", "<cmd>Neogit pull<cr>", desc = "Neogit Pull" },
  },
}
