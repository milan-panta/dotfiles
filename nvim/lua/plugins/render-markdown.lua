return {
  "MeanderingProgrammer/render-markdown.nvim",
  opts = {
    code = {
      sign = false,
      width = "block",
      right_pad = 1,
    },
    -- heading = {
    --   sign = false,
    --   icons = {},
    -- },
    checkbox = {
      enabled = false,
    },
  },
  ft = { "markdown", "norg", "rmd", "org", "codecompanion" },
  config = function(_, opts)
    require("render-markdown").setup(opts)
    Snacks.toggle({
      name = "Render Markdown",
      get = require("render-markdown").get,
      set = require("render-markdown").set,
    }):map("Tm")
    vim.keymap.set("n", "TM", "<cmd>RenderMarkdown<cr>", { desc = "Render Markdown Preview" })
  end,
}
