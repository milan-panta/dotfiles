return {
  "NvChad/nvim-colorizer.lua",
  ft = { "txt", "toml", "css", "html", "typescriptreact", "javascriptreact", "lua" },
  config = function()
    require("colorizer").setup({
      user_default_options = {
        css = true,
        tailwind = true,
        always_update = true,
      },
    })
    vim.keymap.set("n", "tc", "<CMD>ColorizerToggle<CR>", { desc = "Toggle Colorizer" })
  end,
}
