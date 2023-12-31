return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      ensure_installed = {
        "prettierd",
        "clang-format",
      },
      auto_update = true,
    },
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = {
        python = { "ruff" },
      }
      vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "TextChanged" }, {
        callback = function()
          require("lint").try_lint()
        end,
      })
    end,
  },

  {
    "stevearc/conform.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      -- formatting with conform
      local conform = require("conform")
      conform.setup({
        formatters_by_ft = {
          c = { "clang_format" },
          cpp = { "clang_format" },
          lua = { "stylua" },
          python = { "ruff_format", "ruff_fix" },
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
          lsp_fallback = false,
          async = false,
          timeout_ms = 1000,
        })
        vim.cmd("w")
        -- end
      end, { desc = "Format file or range (in visual mode)" })
    end,
  },
}
