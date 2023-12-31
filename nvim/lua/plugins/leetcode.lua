return {
  "kawre/leetcode.nvim",
  build = ":TSUpdate html",
  lazy = "leetcode.nvim" ~= vim.fn.argv()[1],
  dependencies = {
    "nvim-lua/plenary.nvim", -- required by telescope
    "nvim-telescope/telescope.nvim",
    "MunifTanjim/nui.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("leetcode").setup({
      arg = "leetcode.nvim",
      description = {
        show_stats = false,
      },
    })
    require("cmp").setup({ enabled = false })
    vim.cmd("LspStop")
    vim.keymap.set("n", "<Leader>R", function()
      vim.cmd("Leet run")
    end, { desc = "Leetcode run" })
    vim.keymap.set("n", "<Leader>S", function()
      vim.cmd("Leet submit")
    end, { desc = "Leetcode submit" })
    vim.keymap.set("n", "<Leader>C", function()
      vim.cmd("Leet console")
    end, { desc = "Leetcode console" })
  end,
}
