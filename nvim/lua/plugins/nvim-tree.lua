return {
  "nvim-tree/nvim-tree.lua",
  version = "*",
  lazy = false,
  dependencies = {
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("nvim-tree").setup({
      view = {
        width = 20,
      },
    })
    vim.keymap.set("n", "\\", "<CMD>NvimTreeToggle<CR>", { silent = true })
  end,
}
