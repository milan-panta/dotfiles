return {
  "echasnovski/mini.comment",
  dependencies = { {
    "JoosepAlviste/nvim-ts-context-commentstring",
    config = true,
  } },
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    options = {
      custom_commentstring = function()
        return require("ts_context_commentstring.internal").calculate_commentstring() or vim.bo.commentstring
      end,
    },
  },
}
