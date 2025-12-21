return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    options = {
      section_separators = "",
      component_separators = "",
      globalstatus = true,
      theme = {
        normal = {
          a = { fg = "#a9b1d6", bg = "#16161e", gui = "bold" },
          b = { fg = "#565f89", bg = "#16161e" },
          c = { fg = "#565f89", bg = "#16161e" },
        },
        insert = {
          a = { fg = "#9ece6a", bg = "#16161e", gui = "bold" },
          b = { fg = "#565f89", bg = "#16161e" },
          c = { fg = "#565f89", bg = "#16161e" },
        },
        visual = {
          a = { fg = "#e0af68", bg = "#16161e", gui = "bold" },
          b = { fg = "#565f89", bg = "#16161e" },
          c = { fg = "#565f89", bg = "#16161e" },
        },
        replace = {
          a = { fg = "#f7768e", bg = "#16161e", gui = "bold" },
          b = { fg = "#565f89", bg = "#16161e" },
          c = { fg = "#565f89", bg = "#16161e" },
        },
        command = {
          a = { fg = "#7dcfff", bg = "#16161e", gui = "bold" },
          b = { fg = "#565f89", bg = "#16161e" },
          c = { fg = "#565f89", bg = "#16161e" },
        },
        inactive = {
          a = { fg = "#565f89", bg = "#16161e" },
          b = { fg = "#565f89", bg = "#16161e" },
          c = { fg = "#565f89", bg = "#16161e" },
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
        "diagnostics",
        "diff",
        { "filetype", icons_enabled = false },
      },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  },
}
