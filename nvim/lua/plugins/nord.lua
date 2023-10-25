return {
  "shaunsingh/nord.nvim",
  lazy = true,
  priority = 1000,
  event = "VimEnter",
  config = function()
    vim.cmd("colorscheme nord")
  end,
}
