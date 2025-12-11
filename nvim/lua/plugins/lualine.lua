return {
  "nvim-lualine/lualine.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  event = "VeryLazy",
  opts = {
    options = {
      section_separators = "",
      component_separators = "",
    },
    sections = {
      lualine_a = { "mode" },
      lualine_b = { "filename" },
      lualine_c = {
        {
          "diagnostics",
          sections = { "error", "warn" },
          symbols = { error = "", warn = "", info = "", hint = "" },
        },
      },
      lualine_x = { "diff" },
      lualine_y = { "branch" },
      lualine_z = { "location" },
    },
  },
}
