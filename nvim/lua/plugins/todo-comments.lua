return {
  "folke/todo-comments.nvim",
  event = { "BufReadPost", "BufNewFile" },
  opts = {},
  keys = {
    {
      "]t",
      function()
        require("todo-comments").jump_next()
      end,
      desc = "Next todo comment",
    },
    {
      "[t",
      function()
        require("todo-comments").jump_prev()
      end,
      desc = "Previous todo comment",
    },
    {
      "<Leader>ft",
      "<CMD>TodoTelescope<CR>",
      desc = "Telescope todos",
    },
  },
}
