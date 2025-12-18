return {
  "folke/which-key.nvim",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    spec = {
      { "<leader>c", group = "code" },
      { "<leader>d", group = "debug" },
      { "<leader>f", group = "find" },
      { "<leader>g", group = "git" },
      { "<leader>h", group = "hunk" },
      { "<leader>l", group = "lsp" },
      { "<leader>q", group = "session" },
      { "<leader>r", group = "run/refactor" },
      { "<leader>s", group = "search" },
      { "<leader>t", group = "toggle" },
      { "<leader>T", group = "test" },
      { "<leader>u", group = "ui" },
      { "<leader>x", group = "delete (no copy)" },
    },
  },
}
