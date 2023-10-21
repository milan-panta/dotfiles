return {
  "akinsho/toggleterm.nvim",
  cmd = "ToggleTerm",
  -- Unbind Ctrl backslash from vim-tmux-navigator before it's readded by toggleterm
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
      start_in_insert = true,
    })
  end,
}
