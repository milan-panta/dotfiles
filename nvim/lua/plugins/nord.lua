return {
  "shaunsingh/nord.nvim",
  priority = 1000,
  event = "VimEnter",
  config = function()
    vim.cmd("colorscheme nord")
  end,
}
