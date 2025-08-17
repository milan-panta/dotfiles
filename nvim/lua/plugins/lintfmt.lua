return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    event = { "BufReadPost", "BufNewFile", "InsertEnter" },
    opts = {
      ensure_installed = {
        -- formatters
        "stylua",
        "clang-format",
        "prettierd",
        "typstyle",
        "latexindent",
        -- linters / fixers
        "ruff",
      },
      auto_update = true,
      run_on_start = true,
      start_delay = 3000,
      debounce_hours = 12,
    },
  },

  -- Linting
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        python = { "ruff" },
      }

      -- Lint on save and when leaving insert (less noisy than on every TextChanged)
      vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
        callback = function()
          -- Try once; if no linter configured for the ft, it just no-ops
          require("lint").try_lint()
        end,
      })
    end,
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local conform = require("conform")

      conform.setup({
        -- Choose one formatter per ft (order matters when multiple)
        formatters_by_ft = {
          c = { "clang_format" },
          cpp = { "clang_format" },
          -- Make stylua authoritative for Lua
          lua = { "stylua" },
          -- Ruff: apply autofixes then format (Black-compatible)
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

        -- Explicit Stylua args to fix the log error and respect project config
        formatters = {
          stylua = {
            command = "stylua", -- will use mason-installed one if on PATH
            args = {
              "--search-parent-directories",
              "--stdin-filepath",
              "$FILENAME",
              "-", -- read from stdin
            },
            stdin = true,
          },
          -- Example: slightly slower fallback if prettierd isn't running
          prettierd = {
            try_node_modules = true,
          },
        },
      })

      -- Format on save with a small timeout; no LSP fallback for Lua conflicts
      vim.api.nvim_create_autocmd("BufWritePre", {
        callback = function(args)
          local ft = vim.bo[args.buf].filetype
          -- never fallback to LSP for lua; elsewhere you can allow it if you like
          local lsp_fallback = (ft ~= "lua")
          require("conform").format({
            bufnr = args.buf,
            lsp_fallback = lsp_fallback,
            timeout_ms = 1500,
          })
        end,
      })

      -- Manual format key (kept from your config)
      vim.keymap.set({ "n", "v" }, "<Leader>lf", function()
        conform.format({
          lsp_fallback = false, -- keep stylua authoritative for lua
          async = false,
          timeout_ms = 2000,
        })
        vim.cmd("w")
      end, { noremap = true, silent = true, desc = "Format file or range (in visual mode)" })
    end,
  },
}
