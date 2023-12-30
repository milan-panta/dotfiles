return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPost", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    { "folke/neodev.nvim", opts = {} },
    "hrsh7th/cmp-nvim-lsp",
  },

  config = function()
    -- declare variable
    local mason = require("mason")
    local masonLspConfig = require("mason-lspconfig")
    local keymap = vim.keymap
    vim.diagnostic.disable()

    local on_attach = function(_, bufnr)
      local opts = { noremap = true, silent = true }
      opts.buffer = bufnr
      opts.desc = "Go to declaration"
      keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
      opts.desc = "Go to definition"
      keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)
      opts.desc = "Go to references"
      keymap.set("n", "gr", "<cmd>Telescope lsp_references<CR>", opts)
      opts.desc = "Go to next diagnostic"
      keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
      opts.desc = "Go to previous diagnostic"
      keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
      opts.desc = "Lsp hover"
      keymap.set("n", "<S-k>", vim.lsp.buf.hover, opts)
      opts.desc = "Code actions"
      keymap.set("n", "<Leader>la", vim.lsp.buf.code_action, opts)
      opts.desc = "Rename"
      keymap.set("n", "<F2>", vim.lsp.buf.rename, opts)
      opts.desc = "Get signature"
      keymap.set("n", "<leader>lh", vim.lsp.buf.signature_help, opts)
      opts.desc = "Toggle Inlay Hints"
      keymap.set("n", "<Leader>ti", function()
        vim.lsp.inlay_hint(bufnr, nil)
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
        "cssls",
        "emmet_language_server",
        "eslint",
        "marksman",
        "html",
        "jsonls",
        "lua_ls",
        "pyright",
        "svelte",
        "tailwindcss",
        "texlab",
        "tsserver",
      },
    })

    -- default configs for these language servers
    local servers = {
      "cssls",
      "emmet_language_server",
      "eslint",
      "html",
      "marksman",
      "jsonls",
      "pyright",
      "rust_analyzer",
      "svelte",
      "tailwindcss",
      "texlab",
      "tsserver",
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

    lspconfig.clangd.setup({
      on_attach = on_attach,
      capabilities = capabilities,
      cmd = {
        "clangd",
        "--offset-encoding=utf-16",
        "-header-insertion=never",
      },
    })
  end,
}
