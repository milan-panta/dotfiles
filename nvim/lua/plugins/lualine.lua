return {
  "nvim-lualine/lualine.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    options = {
      section_separators = "",
      component_separators = "",
      globalstatus = true,
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { { "branch", icons_enabled = false } },
      lualine_c = {
        { "filename", path = 1 },
      },
      lualine_x = {
        { "diagnostics", colored = false },
        { "diff", colored = false },
        { "filetype", icons_enabled = false },
      },
      lualine_y = { "progress" },
      lualine_z = { { "location" } },
    },
  },
}
