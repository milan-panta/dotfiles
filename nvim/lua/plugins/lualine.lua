return {
  "nvim-lualine/lualine.nvim",
  event = "VeryLazy",
  opts = {
    options = {
      component_separators = "|",
      section_separators = "",
      globalstatus = true,
      disabled_filetypes = {
        statusline = { "dashboard" },
      },
    },
    sections = {
      lualine_x = { "filetype" },
    },
    extensions = { "neo-tree" },
  },
}


