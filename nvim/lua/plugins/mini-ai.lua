return {
  "echasnovski/mini.ai",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    local ai = require("mini.ai")
    require("mini.ai").setup({
      n_lines = 500,
    })
  end,
}
