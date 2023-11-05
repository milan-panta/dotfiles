return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      ensure_installed = {
        "stylua",
        "clang-format",
        "prettierd",
        "latexindent",
        "ruff",
      },
    },
  },

  -- {
  --   "mfussenegger/nvim-lint",
  --   event = { "BufReadPost", "BufNewFile" },
  --   opts = {
  --     events = { "BufWritePost", "BufReadPost", "InsertLeave" },
  --     linters_by_ft = {
  --       python = { "ruff" },
  --     },
  --   },
  -- },

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

  --   config = function()
  --     local lint = require("lint")
  --     lint.events = { "BufWritePost", "BufReadPost", "InsertLeave" }
  --     lint.linters_by_ft = {
  --       python = { "ruff" },
  --     }
  --
  --     -- vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "TextChanged", "TextChangedI" }, {
  --     --   callback = function()
  --     --     require("lint").try_lint()
  --     --   end,
  --     -- })
  --   end,

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
        local filetype = vim.bo.filetype
        if filetype == "tex" then
          vim.cmd("silent w")
          vim.cmd("!latexindent -w %")
        else
          conform.format({
            lsp_fallback = true,
            async = false,
            timeout_ms = 1000,
          })
          vim.cmd("w")
        end
      end, { silent = true, desc = "Format file or range (in visual mode)" })
    end,
  },
}
