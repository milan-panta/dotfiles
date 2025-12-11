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
    { "<leader>gs", "<cmd>Neogit<cr>", desc = "Neogit Status" },
    { "<leader>gc", "<cmd>Neogit commit<cr>", desc = "Neogit Commit" },
    { "<leader>gp", "<cmd>Neogit push<cr>", desc = "Neogit Push" },
    { "<leader>gl", "<cmd>Neogit pull<cr>", desc = "Neogit Pull" },
  },
}
