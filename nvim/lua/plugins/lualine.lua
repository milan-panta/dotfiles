return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    options = {
      section_separators = "",
      component_separators = "|",
      globalstatus = true,
      theme = "auto",
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "branch" },
      lualine_c = {
        { "filetype", icon_only = true, padding = { left = 1, right = 0 } },
        { "filename", path = 1, padding = { left = 0, right = 1 } },
      },
      lualine_x = {
        "diagnostics",
        "diff",
      },
      lualine_y = { "progress" },
      lualine_z = { "location" },
    },
  },
}
