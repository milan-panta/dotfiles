return {
  "RRethy/vim-illuminate",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    large_file_cutoff = 2000,
    large_file_overrides = {
      providers = { "lsp", "treesitter" },
    },
    delay = 0
  },
  config = function(_, opts)
    require("illuminate").configure(opts)
  end,
}
