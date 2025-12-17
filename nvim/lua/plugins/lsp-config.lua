return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "saghen/blink.cmp",
  },
  opts = {
    servers = {
      basedpyright = {},
      clangd = {},
      copilot = {},
      cssls = {},
      eslint = {},
      hls = {},
      html = {},
      jsonls = {},
      marksman = {},
      tailwindcss = {},
      tinymist = {
        settings = {
          formatterMode = "typstyle",
          exportPdf = "never",
        },
      },
      lua_ls = {
        settings = {
          Lua = {
            runtime = { version = "LuaJIT" },
            completion = { callSnippet = "Replace" },
            hint = { enable = true },
            workspace = {
              checkThirdParty = false,
            },
            telemetry = { enable = false },
            diagnostics = {
              disable = { "incomplete-signature-doc", "trailing-space", "missing-local-export-doc" },
              groupSeverity = {
                strong = "Warning",
                strict = "Warning",
              },
              groupFileStatus = {
                ["ambiguity"] = "Opened",
                ["await"] = "Opened",
                ["codestyle"] = "None",
                ["duplicate"] = "Opened",
                ["global"] = "Opened",
                ["luadoc"] = "Opened",
                ["redefined"] = "Opened",
                ["strict"] = "Opened",
                ["strong"] = "Opened",
                ["type-check"] = "Opened",
                ["unbalanced"] = "Opened",
                ["unused"] = "Opened",
                ["unusedLocalExclude"] = { "_*" },
              },
            },
          },
        },
      },
      emmet_language_server = {
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
      },
    },
  },
  config = function(_, opts)
    require("mason-lspconfig").setup({
      ensure_installed = vim.tbl_keys(opts.servers),
      handlers = {
        function(server_name)
          local server_opts = opts.servers[server_name] or {}
          server_opts.capabilities = require("blink.cmp").get_lsp_capabilities(server_opts.capabilities)

          -- Hack to prevent dynamic registration of watched files (performance)
          server_opts.capabilities.workspace = server_opts.capabilities.workspace or {}
          server_opts.capabilities.workspace.didChangeWatchedFiles = {
            dynamicRegistration = false,
          }

          require("lspconfig")[server_name].setup(server_opts)
        end,
      },
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        -- Diagnostic navigation
        map("[e", function()
          vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
        end, "Previous Error")
        map("]e", function()
          vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
        end, "Next Error")

        -- Native LSP Keymaps (Neovim 0.11+ style)
        -- Modified to avoid conflicts with Snacks (gr) and avoid waiting
        map("<leader>rn", vim.lsp.buf.rename, "Rename")
        map("<leader>ca", vim.lsp.buf.code_action, "Code Action")

        -- Signature Help (CTRL-S is common in Insert mode, but 'gK' is standard in Normal)
        map("gK", vim.lsp.buf.signature_help, "Signature Help")

      end,
    })

    vim.diagnostic.config({
      severity_sort = true,
      signs = true,
      underline = true,
    })

    -- Nvim 0.12+ features
    vim.schedule(function()
      if vim.fn.has("nvim-0.12") == 1 then
        vim.lsp.inline_completion.enable(false)
        -- Inline completion keymaps
        vim.keymap.set({ "i", "n" }, "<M-]>", function()
          vim.lsp.inline_completion.select({ count = 1 })
        end, { desc = "Next Copilot suggestion" })

        vim.keymap.set({ "i", "n" }, "<M-[>", function()
          vim.lsp.inline_completion.select({ count = -1 })
        end, { desc = "Prev Copilot suggestion" })

        vim.keymap.set("i", "<C-l>", function()
          if not vim.lsp.inline_completion.get() then
            return "<C-l>"
          end
          -- Accept logic is usually handled by the binding itself or the fallback here
        end, { expr = true, desc = "Accept Copilot inline suggestion" })

        -- Toggle Copilot
        vim.keymap.set("n", "<Leader>tc", function()
          local enabled = vim.lsp.inline_completion.is_enabled()
          vim.lsp.inline_completion.enable(not enabled)
          vim.notify("Copilot " .. (enabled and "disabled" or "enabled"), vim.log.levels.INFO)
        end, { desc = "Toggle Copilot" })
      end
    end)
  end,
}
