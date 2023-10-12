return {
  "goolord/alpha-nvim",
  priority = 800,
  config = function()
    require("alpha").setup(require("alpha.themes.dashboard").config)
  end,
}
