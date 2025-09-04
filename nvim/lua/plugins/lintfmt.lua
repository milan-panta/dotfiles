return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = { "BufReadPost", "BufNewFile", "InsertEnter" },
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
    },
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        python = { "ruff" },
      }

      vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile", "BufWritePost" }, {
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
        formatters_by_ft = {
          c = { "clang_format" },
          cpp = { "clang_format" },
          lua = { "stylua" },
          python = { "ruff_fix", "ruff_format" },
          tex = { "latexindent" },
          html = { "prettierd" },
          typst = { "typstyle" },
          markdown = { "prettierd" },
          javascript = { "prettierd" },
          javascriptreact = { "prettierd" },
          json = { "prettierd" },
          typescript = { "prettierd" },
          typescriptreact = { "prettierd" },
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
          prettierd = {
            try_node_modules = true,
          },
        },
      })

      vim.keymap.set({ "n", "v" }, "<Leader>lf", function()
        conform.format({
          lsp_fallback = false,
          async = false,
          timeout_ms = 2000,
        })
        vim.cmd("w")
      end, { noremap = true, silent = true, desc = "Format file or range (in visual mode)" })
    end,
  },
}
