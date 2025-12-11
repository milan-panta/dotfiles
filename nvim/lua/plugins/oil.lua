return {
  "stevearc/oil.nvim",
  cmd = "Oil",
  keys = {
    { "<space>-", function() require("oil").toggle_float() end, desc = "Open Parent Directory" },
  },
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("oil").setup({
      columns = { "icon" },
      keymaps = {
        ["<C-h>"] = false,
        ["<C-l>"] = false,
        ["<C-k>"] = false,
        ["<C-j>"] = false,
      },
      view_options = {
        show_hidden = true,
      },
      default_file_explorer = false,
    })
  end,
}
