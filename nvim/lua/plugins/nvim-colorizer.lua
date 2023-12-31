return {
  "NvChad/nvim-colorizer.lua",
  event = { "BufReadPost", "BufNewFile" },
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
