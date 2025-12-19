return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    options = {
      section_separators = "",
      component_separators = "",
      globalstatus = true,
      theme = "auto",
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
