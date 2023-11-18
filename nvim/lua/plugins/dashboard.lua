return {
  "nvimdev/dashboard-nvim",
  event = "VimEnter",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    local db = require("dashboard")
    vim.opt.ruler = false
    db.setup({
      config = {
        week_header = {
          enable = true,
        },
        project = {
          limit = 3,
        },
        packages = { enable = false },
        mru = { limit = 3 },
        footer = {},
        disable_move = true,
        shortcut = {
          {
            desc = "Lazy",
            icon = "󰒲 ",
            group = "HGD1",
            action = "Lazy",
            key = "l",
          },
          {
            icon = " ",
            desc = "Files",
            group = "HGD2",
            action = "Telescope fd",
            key = "f",
          },
          {
            icon = " ",
            desc = "Create",
            group = "HGD3",
            action = "ene | startinsert",
            key = "e",
          },
          {
            icon = "󱧃 ",
            desc = "Neorg",
            group = "HGD4",
            action = "Neorg index",
            key = "n",
          },
          {
            icon = " ",
            desc = "Config",
            group = "HGD5",
            action = "Telescope fd cwd=~/.config/nvim/lua prompt_title=Config",
            key = "c",
          },
          {
            icon = " ",
            desc = "Grep",
            group = "HGD6",
            action = "Telescope live_grep",
            key = "g",
          },
          {
            icon = " ",
            desc = "Quit",
            group = "HGD7",
            action = "qa",
            key = "q",
          },
        },
      },
    })
    vim.cmd([[highlight!HGD2 guifg=#33658a]])
    vim.cmd([[highlight!HGD4 guifg=#43aa8b]])
    vim.cmd([[highlight!HGD6 guifg=#90be6d]])
    vim.cmd([[highlight!HGD7 guifg=#f9c74f]])
    vim.cmd([[highlight!HGD3 guifg=#f8961e]])
    vim.cmd([[highlight!HGD5 guifg=#f3722c]])
    vim.cmd([[highlight!HGD1 guifg=#fb5607]])
  end,
}
