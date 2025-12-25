return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        python = { "ruff" },
      }

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
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
      local conform = require("conform")

      conform.setup({
        format_on_save = function(bufnr)
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          return { timeout_ms = 500, lsp_fallback = true }
        end,
        formatters_by_ft = {
          c = { "clang_format" },
          cpp = { "clang_format" },
          lua = { "stylua" },
          python = { "ruff_fix", "ruff_format" },
          tex = { "latexindent" },
          markdown = { "prettier" },
          html = { "prettier" },
          typst = { "typstyle" },
          javascript = { "prettier" },
          javascriptreact = { "prettier" },
          json = { "prettier" },
          typescript = { "prettier" },
          typescriptreact = { "prettier" },
        },

        formatters = {
          stylua = {
            command = "stylua",
            args = {
              "--search-parent-directories",
              "--stdin-filepath",
              "$FILENAME",
              "-",
            },
            stdin = true,
          },
        },
      })

      vim.keymap.set({ "n", "v" }, "<leader>lf", function()
        conform.format({
          lsp_fallback = true,
          async = false,
          timeout_ms = 2000,
        })
        vim.cmd("w")
      end, { noremap = true, silent = true, desc = "Format file or range (in visual mode)" })
    end,
  },
}
