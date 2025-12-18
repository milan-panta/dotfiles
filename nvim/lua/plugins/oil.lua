return {
  "stevearc/oil.nvim",
  cmd = "Oil",
  keys = {
    { "-", function() require("oil").toggle_float() end, desc = "Open Parent Directory" },
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  opts = {
    columns = { "icon" },
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
    view_options = {
      show_hidden = true,
      natural_order = true,
    },
    float = {
      padding = 2,
      max_width = 60,
      max_height = 20,
      border = "rounded",
    },
    keymaps = {
      ["<C-h>"] = false,
      ["<C-l>"] = false,
      ["<C-k>"] = false,
      ["<C-j>"] = false,
      ["q"] = "actions.close",
    },
  },
}
