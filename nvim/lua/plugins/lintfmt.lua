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
      local filetype = vim.bo.filetype
      vim.cmd("w", { silent = true })
      if filetype == "tex" then
        vim.cmd("!latexindent -w %", { silent = true })
      else
        conform.format({
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        })
        vim.cmd("w", { silent = true })
      end
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

-- return {
--   "nvimtools/none-ls.nvim",
--   event = { "BufReadPost", "BufNewFile" },
--   dependencies = {
--     "williamboman/mason.nvim",
--     "jay-babu/mason-null-ls.nvim",
--   },
--   config = function()
--     -- null_ls linters + formatters
--     require("mason-null-ls").setup({
--       ensure_installed = {
--         "stylua",
--         "ruff",
--         "prettierd",
--         "clangd",
--         "clang-format",
--         "latexindent",
--       },
--     })
--
--     local null_ls = require("null-ls")
--
--     local f = null_ls.builtins.formatting
--     local d = null_ls.builtins.diagnostics
--
--     local sources = {
--       --formatting
--       f.prettierd,
--       f.stylua,
--       f.ruff,
--       f.clang_format,
--
--       -- diagnostics
--       d.ruff,
--     }
--
--     null_ls.setup({
--       -- debug = true,
--       sources = sources,
--     })
--
--     function Format()
--       vim.cmd("silent w")
--       local filetype = vim.bo.filetype
--       if filetype == "tex" then
--         vim.cmd("silent !latexindent -w %")
--       else
--         vim.lsp.buf.format({ timeout_ms = 2000 })
--       end
--       vim.cmd("silent w")
--     end
--
--     vim.keymap.set("n", "<Leader>lf", function()
--       Format()
--     end, {desc = "Format code"})
--   end,
-- }
