return {
  "nvim-treesitter/nvim-treesitter-context",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    vim.keymap.set("n", "[w", function()
      require("treesitter-context").go_to_context()
    end, { silent = true })
  end,
}
