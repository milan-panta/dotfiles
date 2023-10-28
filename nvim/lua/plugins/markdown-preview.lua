return {
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreview" },
  build = "cd app && yarn install",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
  end,
  ft = { "markdown" },
}
