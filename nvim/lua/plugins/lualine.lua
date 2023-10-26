return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = function()
    return {
      options = {
        disabled_filetypes = {
          statusline = { "dashboard" },
        },
      },
      extensions = { "neo-tree" },
    }
  end,
}
