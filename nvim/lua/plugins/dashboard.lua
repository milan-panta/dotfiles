return {
  "nvimdev/dashboard-nvim",
  event = "VimEnter",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local db = require("dashboard")
    db.setup({
      config = {
        week_header = {
          enable = true,
        },
        project = {
          enable = false,
        },
        mru = { limit = 3 },
        footer = {},
        disable_move = true,
        shortcut = {
          {
            desc = "Lazy",
            icon = "󰒲 ",
            group = "Include",
            action = "Lazy",
            key = "l",
          },
          {
            icon = " ",
            desc = "Files",
            group = "Function",
            action = "Telescope fd",
            key = "f",
          },
          {
            icon = " ",
            desc = "Config",
            group = "Constant",
            action = "Telescope fd cwd=~/.config/nvim/lua prompt_title=Config",
            key = "c",
          },
          {
            icon = " ",
            desc = "Grep",
            group = "Function",
            action = "Telescope live_grep",
            key = "g",
          },
          {
            icon = " ",
            desc = "Quit",
            group = "String",
            action = "qa",
            key = "q",
          },
        },
      },
    })
  end,
}
