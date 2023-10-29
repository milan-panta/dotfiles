return {
  "kawre/leetcode.nvim",
  build = ":TSUpdate html",
  lazy = "leetcode.nvim" ~= vim.fn.argv()[1],
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-lua/plenary.nvim", -- required by telescope
    "nvim-telescope/telescope.nvim",
    "MunifTanjim/nui.nvim",

    -- optional
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
        vim.cmd("<Leader>cc")
        vim.cmd("Leet run")
      end,
      desc = "Leetcode run",
      silent = true,
    },
    {
      "<Leader>cs",
      function()
        vim.cmd("<Leader>cc")
        vim.cmd("Leet submit")
      end,
      desc = "Leetcode submit",
      silent = true,
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
