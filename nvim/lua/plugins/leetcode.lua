return {
  "kawre/leetcode.nvim",
  build = ":TSUpdate html",
  lazy = "leetcode.nvim" ~= vim.fn.argv()[1],
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "MunifTanjim/nui.nvim",
    "folke/noice.nvim",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("leetcode").setup({
      arg = "leetcode.nvim",
      lang = "python3",
    })
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
