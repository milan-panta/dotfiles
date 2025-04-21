return {
  "sainnhe/gruvbox-material",
  lazy = true,
  priority = 1000,
  config = function()
    vim.g.gruvbox_material_background = "medium"
    vim.g.gruvbox_material_better_performance = 1
    vim.cmd("colorscheme gruvbox-material")
  end,
}
