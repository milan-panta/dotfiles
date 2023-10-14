return {
  "Wansmer/treesj",
  event = { "BufReadPre", "BufNewFile" },
  keys = { "<space>m", "<space>j", "<space>s" },
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  config = function()
    require("treesj").setup({--[[ your config ]]
    })
  end,
}
