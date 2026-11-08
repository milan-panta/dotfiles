return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
  },
  keys = {
    { "<M-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Window or tmux pane left" },
    { "<M-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Window or tmux pane down" },
    { "<M-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Window or tmux pane up" },
    { "<M-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Window or tmux pane right" },
  },
  init = function()
    vim.g.tmux_navigator_no_mappings = 1 -- disable defaults, we use custom M-hjkl
  end,
}
