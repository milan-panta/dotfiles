return {
  -- 1. Mason: installs LSPs, DAPs, linters, etc.
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },

  -- 2. mason-lspconfig: bridges Mason <-> nvim-lspconfig
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig", -- make sure lspconfig is loaded first
    },
    opts = {
      -- Only controls *installation*.
      -- Enabling is done via vim.lsp.enable() below.
      ensure_installed = {
        "basedpyright",
        "clangd",
        "copilot",
        "cssls",
        "emmet_language_server",
        "eslint",
        "hls",
        "html",
        "jsonls",
        "lua_ls",
        "marksman",
        "rust_analyzer",
        "tailwindcss",
        "tinymist",
      },
    },
  },

  -- 3. LSP config (Neovim 0.11+ style)
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "saghen/blink.cmp",
    },
    config = function()
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
          vim.diagnostic.jump({
            count = -1,
            severity = vim.diagnostic.severity.ERROR,
          })
        end, opts)
        vim.keymap.set("n", "]e", function()
          vim.diagnostic.jump({
            count = 1,
            severity = vim.diagnostic.severity.ERROR,
          })
        end, opts)

        if client.server_capabilities.inlayHintProvider then
          vim.keymap.set("n", "<Leader>ti", function()
            local ih = vim.lsp.inlay_hint
            local enabled = ih.is_enabled({ buf = bufnr })
            ih.enable(not enabled, { buf = bufnr })
          end, opts)
        end
      end

      -- Global defaults for all LSP servers (on_attach + blink capabilities)
      vim.lsp.config("*", {
        capabilities = capabilities,
        on_attach = on_attach,
      })

      -- Server-specific overrides
      vim.lsp.config("tinymist", {
        settings = {
          formatterMode = "typstyle",
          exportPdf = "never",
        },
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            completion = { callSnippet = "Replace" },
            diagnostics = { globals = { "vim", "require" } },
            hint = { enable = true },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = { enable = false },
          },
        },
      })

      vim.lsp.config("emmet_language_server", {
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

      -- Enable all the servers (this replaces lspconfig[server].setup)
      vim.lsp.enable({
        "basedpyright",
        "clangd",
        "copilot",
        "cssls",
        "emmet_language_server",
        "eslint",
        "hls",
        "html",
        "jsonls",
        "lua_ls",
        "marksman",
        "rust_analyzer",
        "tailwindcss",
        "tinymist",
      })

      vim.diagnostic.config({
        severity_sort = true,
        signs = true,
        underline = true,
      })
    end,
  },
}

