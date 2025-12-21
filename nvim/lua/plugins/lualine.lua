return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    options = {
      section_separators = "",
      component_separators = { left = "│", right = "│" },
      globalstatus = true,
      theme = {
        normal = {
          a = { fg = "#7aa2f7", bg = "#16161e", gui = "bold" },
          b = { fg = "#bb9af7", bg = "#16161e" },
          c = { fg = "#a9b1d6", bg = "#16161e" },
          z = { fg = "#7aa2f7", bg = "#16161e", gui = "bold" },
        },
        insert = {
          a = { fg = "#7aa2f7", bg = "#16161e", gui = "bold" },
          b = { fg = "#bb9af7", bg = "#16161e" },
          c = { fg = "#a9b1d6", bg = "#16161e" },
          z = { fg = "#7aa2f7", bg = "#16161e", gui = "bold" },
        },
        visual = {
          a = { fg = "#7aa2f7", bg = "#16161e", gui = "bold" },
          b = { fg = "#bb9af7", bg = "#16161e" },
          c = { fg = "#a9b1d6", bg = "#16161e" },
          z = { fg = "#7aa2f7", bg = "#16161e", gui = "bold" },
        },
        replace = {
          a = { fg = "#7aa2f7", bg = "#16161e", gui = "bold" },
          b = { fg = "#bb9af7", bg = "#16161e" },
          c = { fg = "#a9b1d6", bg = "#16161e" },
          z = { fg = "#7aa2f7", bg = "#16161e", gui = "bold" },
        },
        command = {
          a = { fg = "#7aa2f7", bg = "#16161e", gui = "bold" },
          b = { fg = "#bb9af7", bg = "#16161e" },
          c = { fg = "#a9b1d6", bg = "#16161e" },
          z = { fg = "#7aa2f7", bg = "#16161e", gui = "bold" },
        },
        inactive = {
          a = { fg = "#565f89", bg = "#16161e" },
          b = { fg = "#565f89", bg = "#16161e" },
          c = { fg = "#565f89", bg = "#16161e" },
          z = { fg = "#565f89", bg = "#16161e" },
        },
      },
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch" },
      lualine_c = {
        { "filename", path = 1 },
      },
      lualine_x = {
        { "diagnostics", colored = false },
        { "diff", colored = false },
        { "filetype", icons_enabled = false },
      },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  },
}
