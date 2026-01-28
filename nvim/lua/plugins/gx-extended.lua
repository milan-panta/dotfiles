return {
  "rmagatti/gx-extended.nvim",
  keys = { "gx" },
  config = function()
    require("gx-extended").setup({
      open_fn = function(url)
        vim.ui.open(url)
      end,
    })
  end,
}
