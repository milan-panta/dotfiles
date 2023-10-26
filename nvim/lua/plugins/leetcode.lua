return {
  "kawre/leetcode.nvim",
  build = ":TSUpdate html",
  lazy = "leetcode.nvim" ~= vim.fn.argv()[1],
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-telescope/telescope.nvim",
    "nvim-lua/plenary.nvim", -- required by telescope
    "MunifTanjim/nui.nvim",

    -- optional
    -- "rcarriga/nvim-notify",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    arg = "leetcode.nvim",
    lang = "python",
  },
  keys = {
    {
      "<Leader>cr",
      function()
        vim.cmd("Leet run")
      end,
      desc = "Leetcode run",
    },
    {
      "<Leader>cs",
      function()
        vim.cmd("Leet submit")
      end,
      desc = "Leetcode submit",
    },
    {
      "<Leader>cc",
      function()
        vim.cmd("Leet console")
      end,
      desc = "Leetcode console",
    },
  },
}
