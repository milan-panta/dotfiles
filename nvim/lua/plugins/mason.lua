return {
  {
    "williamboman/mason.nvim",
    keys = { { "<leader>m", "<cmd>Mason<cr>", desc = "Mason" } },
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = true,
    dependencies = { "williamboman/mason.nvim" },
    opts = {
      ensure_installed = {
        "stylua",
        "clang-format",
        "prettierd",
        "typstyle",
        "latexindent",
        "ruff",
      },
      auto_update = true,
      run_on_start = true,
    },
  },
}
