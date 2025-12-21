return {
  "iamcco/markdown-preview.nvim",
  build = "cd app && yarn install",
  ft = { "markdown" },
  -- markdown preview runner
  cmd = { "MarkdownPreview" },
  keys = {
    { "<leader>rm", "<cmd>MarkdownPreviewToggle<cr>", { desc = "Markdown preview" } },
  },
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
  end,
}
