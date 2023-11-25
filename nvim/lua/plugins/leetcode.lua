return {
  "kawre/leetcode.nvim",
  build = ":TSUpdate html",
  lazy = "leetcode.nvim" ~= vim.fn.argv()[1],
  dependencies = {
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim", -- required by telescope
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
    vim.diagnostic.disable()
    vim.keymap.set("n", "<Leader>cr", function()
      vim.cmd("Leet run")
    end, { desc = "Leetcode run" })
    vim.keymap.set("n", "<Leader>cs", function()
      vim.cmd("Leet submit")
    end, { desc = "Leetcode submit" })
    vim.keymap.set("n", "<Leader>cc", function()
      vim.cmd("Leet console")
    end, { desc = "Leetcode console" })
  end,
}
