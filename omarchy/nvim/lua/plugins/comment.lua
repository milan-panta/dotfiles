return {
  {
    "numToStr/Comment.nvim",
    dependencies = { "JoosepAlviste/nvim-ts-context-commentstring" },
    -- After the first screen is drawn, so opening a file doesn't wait for it.
    event = "VeryLazy",
    opts = function()
      return {
        -- treesitter-aware comment style (handles JSX, Vue, etc.)
        pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
      }
    end,
  },
  {
    "JoosepAlviste/nvim-ts-context-commentstring",
    lazy = true,
    opts = {
      enable_autocmd = false,
    },
  },
}
