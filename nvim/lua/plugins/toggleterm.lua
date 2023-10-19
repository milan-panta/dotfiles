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
    local Terminal = require("toggleterm.terminal").Terminal
    local lazygit = Terminal:new({
      cmd = "lazygit",
      dir = "git_dir",
      direction = "float",
      float_opts = {
        border = "double",
      },
      -- function to run on opening the terminal
      on_open = function(term)
        vim.cmd("startinsert!")
        vim.api.nvim_buf_set_keymap(term.bufnr, "n", "q", "<cmd>close<CR>", { noremap = true, silent = true })
      end,
      -- function to run on closing the terminal
      on_close = function()
        vim.cmd("startinsert!")
      end,
    })

    function _LAZYGIT_TOGGLE()
      lazygit:toggle()
    end
  end,
  keys = {
    {
      "<Leader>g",
      "<cmd>lua _LAZYGIT_TOGGLE()<CR>",
      desc = "Open Lazygit",
      noremap = true,
      silent = true,
    },
  },
}
