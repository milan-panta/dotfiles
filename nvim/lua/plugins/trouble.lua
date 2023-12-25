return {
  "folke/trouble.nvim",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = { "nvim-tree/nvim-web-devicons", "folke/todo-comments.nvim" },
  keys = {
    {
      "<Leader>tt",
      "<CMD>TroubleToggle<CR>",
      desc = "Trouble toggle",
    },
  },
}
