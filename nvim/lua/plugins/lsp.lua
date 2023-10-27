return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    {
      "williamboman/mason-lspconfig.nvim",
      event = { "BufReadPre", "BufNewFile" },
    },
    {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      event = { "BufReadPre", "BufNewFile" },
    },
    {
      "williamboman/mason.nvim",
      event = { "BufReadPre", "BufNewFile" },
    },
    {
      "hrsh7th/cmp-nvim-lsp",
      event = { "BufReadPre", "BufNewFile" },
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
    -- declare variable
    local mason = require("mason")
    local masonLspConfig = require("mason-lspconfig")
    local keymap = vim.keymap

    local on_attach = function(_, bufnr)
      local opts = { noremap = true, silent = true }
      opts.buffer = bufnr
      opts.desc = "Go to declaration"
      keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
      opts.desc = "Go to definition"
      keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
      opts.desc = "Go to references"
      keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)
      opts.desc = "Diagnostics open float"
      keymap.set("n", "gl", vim.diagnostic.open_float, opts)
      opts.desc = "Go to next diagnostic"
      keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
      opts.desc = "Go to previous diagnostic"
      keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
      opts.desc = "Lsp hover"
      keymap.set("n", "<Leader>h", vim.lsp.buf.hover, opts)
      opts.desc = "Code actions"
      keymap.set("n", "<Leader>la", vim.lsp.buf.code_action, opts)
      opts.desc = "Rename"
      keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
      opts.desc = "Get signature"
      keymap.set("n", "<leader>lh", vim.lsp.buf.signature_help, opts)
      opts.desc = "Toggle Inlay Hints"
      keymap.set("n", "<Leader>ti", function()
        vim.lsp.inlay_hint(0, nil)
      end, opts)
    end

    local capabilities = require("cmp_nvim_lsp").default_capabilities()
    local lspconfig = require("lspconfig")

    mason.setup({
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    -- lsps
    masonLspConfig.setup({
      ensure_installed = {
        -- lua
        "lua_ls",
        -- web dev
        "emmet_ls",
        "eslint",
        "tsserver",
        "cssls",
        "html",
        "jsonls",
        -- c/cpp
        "clangd",
        -- python
        "pyright",
        -- rust
        "rust_analyzer",
      },
    })

    -- default configs for these language servers
    local servers = {
      "emmet_ls",
      "tsserver",
      "jsonls",
      "eslint",
      "cssls",
      "rust_analyzer",
      "pyright",
    }

    -- configure with default lsp settings
    for _, lsp in ipairs(servers) do
      lspconfig[lsp].setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })
    end

    -- manually configure
    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      settings = {
        Lua = {
          diagnostics = {
            globals = { "vim", "bufnr" },
          },
        },
      },
      on_attach = on_attach,
    })

    lspconfig.html.setup({
      filetypes = { "html", "htmldjango" },
      capabilities = capabilities,
      on_attach = on_attach,
    })

    lspconfig.clangd.setup({
      on_attach = on_attach,
      capabilities = capabilities,
      cmd = {
        "clangd",
        "--offset-encoding=utf-16",
      },
    })

    -- debugging
    require("mason-nvim-dap").setup({
      ensure_installed = { "python" },
      automatic_installation = true,
    })

    -- installing linters and formatters
    require("mason-tool-installer").setup({
      ensure_installed = {
        "stylua",
        "eslint_d",
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
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
    }

    vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "TextChanged", "TextChangedI" }, {
      callback = function()
        require("lint").try_lint()
      end,
    })
  end,
}
