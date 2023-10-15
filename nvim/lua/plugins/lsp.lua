return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    {
      "williamboman/mason.nvim",
      event = "VeryLazy",
    },
    {
      "williamboman/mason-lspconfig.nvim",
      event = { "BufReadPre", "BufNewFile" },
    },
    {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      event = "VeryLazy",
    },
    {
      "hrsh7th/cmp-nvim-lsp",
      event = { "BufReadPre", "BufNewFile" },
    },
    {
      "mfussenegger/nvim-dap",
      event = { "BufReadPre", "BufNewFile" },
    },
    {
      "jay-babu/mason-nvim-dap.nvim",
      event = { "BufReadPre", "BufNewFile" },
    },
    {
      "rcarriga/nvim-dap-ui",
      event = { "BufReadPre", "BufNewFile" },
      dependencies = "mfussenegger/nvim-dap",
    },
    {
      "stevearc/conform.nvim",
      event = { "BufReadPre", "BufNewFile" },
    },
    {
      "mfussenegger/nvim-lint",
      event = { "BufReadPre", "BufNewFile" },
    },
  },
  config = function()
    require("configs.lspconfig")
  end,
}
