return {
  "catppuccin/nvim",
  -- lazy = true,
  priority = 1000,
  -- TODO: define custom colors for boarders and completion highlights
  config = function()
    -- require("catppuccin").setup({
    --   color_overrides = {},
    --   custom_highlights = function()
    --     return {
    --       CmpSel = { bg = "#E4BfB6", fg = "Black" },
    --     }
    --   end,
    -- })
    -- setup must be called before loading
    vim.cmd.colorscheme("catppuccin")
  end,
}
