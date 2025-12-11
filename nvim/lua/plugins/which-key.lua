return {
  "folke/which-key.nvim",
  event = { "BufReadPost", "BufNewFile" },
  init = function()
    vim.o.timeout = true
    vim.o.timeoutlen = 200
  end,
  config = true,
}
