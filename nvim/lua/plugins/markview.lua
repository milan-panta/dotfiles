return {
  "OXY2DEV/markview.nvim",
  keys = {
    { "<Leader>Tm", "<cmd>Markview Toggle<cr>", desc = "Toggle markview in buffer" },
    { "<Leader>TM", "<cmd>Markview splitToggle<cr>", desc = "Toggle markview splitview" },
  },
  ft = "markdown",

  -- Completion for `blink.cmp`
  dependencies = { "saghen/blink.cmp" },
}
