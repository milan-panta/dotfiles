return {
  "nvim-treesitter/nvim-treesitter-context",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local tc = require("treesitter-context")

    tc.setup({})

    vim.keymap.set("n", "[w", function()
      tc.go_to_context()
    end, { silent = true, desc = "Treesitter Context: jump up" })
  end,
}
