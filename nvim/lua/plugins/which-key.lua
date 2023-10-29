return {
  "folke/which-key.nvim",
  event = { "BufReadPost", "BufNewFile" },
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 300
  end,
  config = true,
}
