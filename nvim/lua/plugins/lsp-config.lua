return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
  config = function()
    local mason = require("mason")
    local masonLspConfig = require("mason-lspconfig")
    local lspconfig = require("lspconfig")
    local capabilities = require("blink.cmp").get_lsp_capabilities()
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
      vim.keymap.set("n", "[d", function()
        vim.diagnostic.jump({ count = -1 })
      end, opts)
      vim.keymap.set("n", "]d", function()
        vim.diagnostic.jump({ count = 1 })
      end, opts)
      vim.keymap.set("n", "[e", function()
        vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
      end, opts)
      vim.keymap.set("n", "]e", function()
        vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
      end, opts)
      if client.server_capabilities.inlayHintProvider then
        vim.keymap.set("n", "<Leader>ti", function()
          local ih = vim.lsp.inlay_hint
          local enabled = ih.is_enabled({ buf = bufnr })
          ih.enable(not enabled, { buf = bufnr })
        end, opts)
      end
    end
    mason.setup({
      ui = {
        border = "rounded",
        icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" },
      },
    })
    masonLspConfig.setup({
      ensure_installed = {
        "basedpyright",
        "cssls",
        "emmet_language_server",
        "eslint",
        "html",
        "jsonls",
        "marksman",
        "rust_analyzer",
        "tailwindcss",
        "tinymist",
      },
    })
    local servers =
      { "basedpyright", "clangd", "cssls", "eslint", "html", "jsonls", "marksman", "rust_analyzer", "tailwindcss" }
    for _, lsp in ipairs(servers) do
      lspconfig[lsp].setup({ capabilities = capabilities, on_attach = on_attach })
    end
    lspconfig.tinymist.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = { formatterMode = "typstyle", exportPdf = "never" },
    })
    lspconfig.lua_ls.setup({
      capabilities = capabilities,
      on_attach = on_attach,
      settings = {
        Lua = {
          completion = { callSnippet = "Replace" },
          diagnostics = { globals = { "vim" } },
          hint = { enable = true },
          workspace = { checkThirdParty = false },
          telemetry = { enable = false },
        },
      },
    })
    lspconfig.emmet_language_server.setup({
      capabilities = capabilities,
      on_attach = on_attach,
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
      init_options = { showSuggestionsAsSnippets = true },
    })
    vim.diagnostic.config({
      virtual_text = { spacing = 2, prefix = "●", source = "if_many" },
      float = { border = "rounded", source = "always" },
      severity_sort = true,
      signs = true,
      underline = true,
    })
  end,
}
