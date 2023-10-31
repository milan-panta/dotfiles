return {
  -- Ensure tmux keybind is removed before toggleterm loads
  {
    "christoomey/vim-tmux-navigator",
    event = "VeryLazy",

    config = function()
      vim.keymap.del("n", "<C-\\>")
    end,
  },
  {
    "akinsho/toggleterm.nvim",
    cmd = "ToggleTerm",
    keys = {
      {
        "\x1c",
        "<cmd>ToggleTerm<CR>",
        desc = "Open Toggle Term",
      },
    },
    config = function()
      require("toggleterm").setup({
        open_mapping = [[<c-\>]],
        start_in_insert = true,
      })
    end,
  },
}
