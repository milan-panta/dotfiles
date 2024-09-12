return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "hrsh7th/cmp-nvim-lsp",
  },

  config = function()
    -- declare variable
    local mason = require("mason")
    local masonLspConfig = require("mason-lspconfig")

    local on_attach = function(client, bufnr)
      local opts = { buffer = bufnr, noremap = true, silent = true }
      vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
      vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
      vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
      vim.keymap.set("n", "<Leader>la", vim.lsp.buf.code_action, opts)
      vim.keymap.set("n", "<Leader>wa", vim.lsp.buf.add_workspace_folder, opts)
      vim.keymap.set("n", "<Leader>wr", vim.lsp.buf.remove_workspace_folder, opts)
      vim.keymap.set("n", "<Leader>wl", function()
        print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
      end, opts)
      vim.keymap.set("n", "<Leader>lr", vim.lsp.buf.rename, opts)
      vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
      vim.keymap.set("n", "<Leader>e", vim.diagnostic.open_float, opts)
      vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
      vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
      if client.supports_method("textDocument/inlayHint") then
        vim.keymap.set("n", "<Leader>ti", function()
          vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr }), { bufnr })
        end, opts)
      end
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
        "clangd",
        "cssls",
        "emmet_language_server",
        "eslint",
        "gopls",
        "html",
        "jsonls",
        "lua_ls",
        "marksman",
        "pyright",
        "rust_analyzer",
        "tailwindcss",
      },
    })

    -- default configs for these language servers
    local servers = {
      "cssls",
      "emmet_language_server",
      "eslint",
      "gopls",
      "hls",
      "html",
      "jsonls",
      "marksman",
      "pyright",
      "rust_analyzer",
      "tailwindcss",
    }

    -- configure with default lsp settings
    for _, lsp in ipairs(servers) do
      lspconfig[lsp].setup({
        capabilities = capabilities,
        on_attach = on_attach,
      })
    end

    lspconfig.clangd.setup({
      on_attach = on_attach,
      cmd = {
        "/opt/homebrew/opt/llvm/bin/clangd",
        "--background-index",
        "--pch-storage=memory",
        "--all-scopes-completion",
        "--pretty",
        "--header-insertion=never",
        "-j=4",
        "--header-insertion-decorators",
        "--function-arg-placeholders",
        "--completion-style=detailed",
      },
      filetypes = { "c", "cpp", "objc", "objcpp" },
      root_dir = require("lspconfig").util.root_pattern("src"),
      init_option = { fallbackFlags = { "-std=c++2a" } },
      capabilities = capabilities,
    })

    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      settings = {
        Lua = {
          completion = {
            callSnippet = "Replace",
          },
          diagnostics = {
            globals = { "vim", "bufnr" },
          },
          hint = { enable = true },
        },
      },
      on_attach = on_attach,
    })

    lspconfig.emmet_language_server.setup({
      filetypes = {
        "css",
        "eruby",
        "html",
        "javascript",
        "javascriptreact",
        "less",
        "pug",
        "sass",
        "scss",
        "typescriptreact",
      },
      init_options = {
        showSuggestionsAsSnippets = true,
      },
    })
  end,
}
