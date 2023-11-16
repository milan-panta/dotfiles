return {
  "folke/noice.nvim",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    views = {
      hover = {
        border = {
          style = "rounded",
        },
        win_options = {
          winhighlight = { Normal = "Normal", FloatBorder = "Normal" },
        },
        position = { row = 2, col = 2 },
      },
    },
    cmdline = {
      enabled = false,
    },
    messages = {
      enabled = false,
    },
  },
  -- stylua: ignore
  keys = {
    { "<C-f>", function() if not require("noice.lsp").scroll(4) then return "<c-f>" end end, silent = true, expr = true, desc = "Scroll forward", mode = {"i", "n", "s"} },
    { "<C-b>", function() if not require("noice.lsp").scroll(-4) then return "<c-b>" end end, silent = true, expr = true, desc = "Scroll backward", mode = {"i", "n", "s"}},
  },
}
