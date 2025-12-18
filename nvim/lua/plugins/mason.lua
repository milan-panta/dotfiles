return {
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
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
    cmd = "MasonToolsInstall",
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
