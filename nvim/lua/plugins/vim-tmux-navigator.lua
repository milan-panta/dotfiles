return {
  "christoomey/vim-tmux-navigator",
  event = "VeryLazy",

  config = function()
    vim.keymap.del("n", "<C-\\>")
  end,
}
