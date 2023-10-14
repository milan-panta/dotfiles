return {
  "akinsho/toggleterm.nvim",
  event = "VeryLazy",
  -- To unbind Ctrl backslash before it's readded by toggleterm
  dependencies = {
    "christoomey/vim-tmux-navigator",
    event = "VeryLazy",

    config = function()
      vim.keymap.del("n", "<C-\\>")
    end,
  },
  config = function()
    require("toggleterm").setup({
      open_mapping = [[<c-\>]],
      direction = "float",
      start_in_insert = true,
    })
  end,
}
