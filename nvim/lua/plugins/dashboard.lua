return {
  "nvimdev/dashboard-nvim",
  event = "VimEnter",
  config = function()
    local db = require("dashboard")
    db.setup({
      theme = "hyper",
      config = {
        week_header = {
          enable = true,
        },
        project = {
          enable = true,
        },
        disable_move = true,
        shortcut = {
          {
            desc = "Update",
            icon = " ",
            group = "Include",
            action = "Lazy update",
            key = "u",
          },
          {
            icon = " ",
            desc = "Files",
            group = "Function",
            action = "Telescope fd find_command=rg,--ignore,--hidden,--files",
            key = "f",
          },
          {
            icon = " ",
            desc = "Apps",
            group = "String",
            action = "Telescope fd cwd=/Applications prompt_title=Applications",
            key = "a",
          },
          {
            icon = " ",
            desc = "Config",
            group = "Constant",
            action = "Telescope fd cwd=~/.config/nvim/lua prompt_title=Config",
            key = "d",
          },
        },
      },
    })
  end,
}
