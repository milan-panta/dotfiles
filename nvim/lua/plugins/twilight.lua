return {
  "folke/twilight.nvim",
  keys = {
    {
      "<Leader>tl",
      function()
        vim.cmd("Twilight")
      end,
      desc = "Toggles Twilight",
    },
  },
  opts = {
    -- your configuration comes here
    -- or leave it empty to use the default settings
    -- refer to the configuration section below
  },
}
