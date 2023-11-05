return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  keys = { { "<Leader>ts", "<cmd>Copilot suggestion<CR>", desc = "Toggle Copilot Suggestions" } },
  config = function()
    require("copilot").setup({
      suggestion = {
        keymap = {
          accept = "<S-Tab>",
        },
      },
    })
  end,
}
