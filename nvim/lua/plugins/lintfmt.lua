return {
  "stevearc/conform.nvim",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    "mfussenegger/nvim-lint",
  },
  config = function()
    -- installing linters and formatters
    require("mason-tool-installer").setup({
      ensure_installed = {
        "stylua",
        "clang-format",
        "prettierd",
        "latexindent",
        "ruff",
      },
      auto_update = true,
    })

    -- formatting with conform
    local conform = require("conform")
    conform.setup({
      formatters_by_ft = {
        c = { "clang_format" },
        cpp = { "clang_format" },
        lua = { "stylua" },
        python = { "ruff_fix", "ruff_format" },
        tex = { "latexindent" },
        markdown = { "prettierd" },
        javascript = { "prettierd" },
        javascriptreact = { "prettierd" },
        typescript = { "prettierd" },
        typescriptreact = { "prettierd" },
      },
    })

    vim.keymap.set({ "n", "v" }, "<Leader>lf", function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      })
      vim.cmd("silent :w")
    end, { desc = "Format file or range (in visual mode)" })

    -- linting with nvim-lint
    local lint = require("lint")

    lint.linters_by_ft = {
      python = { "ruff" },
    }

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "TextChanged", "TextChangedI" }, {
      callback = function()
        require("lint").try_lint()
      end,
    })
  end,
}
