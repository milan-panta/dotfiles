return {
  "stevearc/oil.nvim",
  cmd = "Oil",
  keys = {
    { "<Leader>-", "<cmd>Oil<cr>", desc = "Open Oil" },
  },
  dependencies = { { "nvim-mini/mini.icons", opts = {} } },
  opts = {
    default_file_explorer = true,
    view_options = {
      show_hidden = true,
    },
  },
}
