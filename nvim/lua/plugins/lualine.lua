local colors = {
  blue = "#7aa2f7",
  bg = "#16161e",
  purple = "#bb9af7",
  fg = "#a9b1d6",
  grey = "#565f89",
}

local theme_config = {
  a = { fg = colors.blue, bg = colors.bg, gui = "bold" },
  b = { fg = colors.purple, bg = colors.bg },
  c = { fg = colors.fg, bg = colors.bg },
  z = { fg = colors.blue, bg = colors.bg, gui = "bold" },
}

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
        normal = theme_config,
        insert = theme_config,
        visual = theme_config,
        replace = theme_config,
        command = theme_config,
        inactive = theme_config,
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
