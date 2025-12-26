return {
  "christoomey/vim-tmux-navigator",
  cmd = {
    "TmuxNavigateLeft",
    "TmuxNavigateDown",
    "TmuxNavigateUp",
    "TmuxNavigateRight",
  },
  keys = {
    { "<M-h>", "<cmd>TmuxNavigateLeft<cr>" },
    { "<M-j>", "<cmd>TmuxNavigateDown<cr>" },
    { "<M-k>", "<cmd>TmuxNavigateUp<cr>" },
    { "<M-l>", "<cmd>TmuxNavigateRight<cr>" },
  },
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
}