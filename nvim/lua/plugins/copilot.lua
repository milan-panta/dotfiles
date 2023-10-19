return {
  "zbirenbaum/copilot.lua",
  cmd = "Copilot",
  config = function()
    require("copilot").setup({
      suggestion = {
        keymap = {
          accept = "<Tab>",
        },
      },
    })
  end,
}
