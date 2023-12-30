return {
  "nguyenvukhang/nvim-toggler",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("nvim-toggler").setup({
      -- your own inverses
      inverses = {
        ["True"] = "False",
        ["true"] = "false",
      },
      -- removes the default set of inverses
      remove_default_inverses = true,
    })
    vim.keymap.set({ "n", "v" }, "<Leader>~", require("nvim-toggler").toggle)
  end,
}
