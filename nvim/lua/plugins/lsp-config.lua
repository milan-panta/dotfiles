return {
  "neovim/nvim-lspconfig",
  event = "VeryLazy",
  dependencies = {
    "williamboman/mason.nvim",
    "williamboman/mason-lspconfig.nvim",
    "saghen/blink.cmp",
  },
  opts = {
    servers = {
      basedpyright = {},
      -- copilot = {},
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
            codeLens = { enable = true },
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
    local function setup_server(server_name)
      local server_opts = opts.servers[server_name] or {}
      server_opts.capabilities = require("blink.cmp").get_lsp_capabilities(server_opts.capabilities)

      -- Hack to prevent dynamic registration of watched files (performance)
      server_opts.capabilities.workspace = server_opts.capabilities.workspace or {}
      server_opts.capabilities.workspace.didChangeWatchedFiles = {
        dynamicRegistration = false,
      }
      return server_opts
    end

    require("mason-lspconfig").setup({
      ensure_installed = vim.tbl_keys(opts.servers),
      handlers = {
        function(server_name)
          local server_opts = setup_server(server_name)
          if opts.setup and opts.setup[server_name] then
            -- vim.notify("Running custom setup for " .. server_name)
            if opts.setup[server_name](server_name, server_opts) then
              return
            end
          end
          require("lspconfig")[server_name].setup(server_opts)
        end,
      },
    })
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp-attach", { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or "n"
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        -- local client = vim.lsp.get_client_by_id(event.data.client_id)
        -- if client then
        --   client.server_capabilities.semanticTokensProvider = nil
        -- end

        -- Delete Neovim 0.11+ default LSP keymaps (we define our own)
        pcall(vim.keymap.del, "n", "grn", { buffer = event.buf })
        pcall(vim.keymap.del, { "n", "x" }, "gra", { buffer = event.buf })
        pcall(vim.keymap.del, "n", "grr", { buffer = event.buf })
        pcall(vim.keymap.del, "n", "gri", { buffer = event.buf })
        pcall(vim.keymap.del, "n", "gO", { buffer = event.buf })
        pcall(vim.keymap.del, "i", "<C-S>", { buffer = event.buf })

        -- Hover (K is default in 0.10+ but we explicitly set it)
        map("K", vim.lsp.buf.hover, "Hover Documentation")

        -- Diagnostic navigation (all severities)
        map("[d", function()
          vim.diagnostic.jump({ count = -1 })
        end, "Previous Diagnostic")
        map("]d", function()
          vim.diagnostic.jump({ count = 1 })
        end, "Next Diagnostic")

        -- Diagnostic navigation (errors only)
        map("[e", function()
          vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
        end, "Previous Error")
        map("]e", function()
          vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
        end, "Next Error")

        -- Diagnostic float
        map("<C-W>d", vim.diagnostic.open_float, "Line Diagnostics")

        -- Rename & Code Action
        map("<leader>rn", vim.lsp.buf.rename, "Rename")
        map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
        map("<leader>ca", vim.lsp.buf.code_action, "Code Action", "x")

        map("<C-k>", vim.lsp.buf.signature_help, "Signature Help", "i")
        map("<leader>cc", vim.lsp.codelens.run, "Run Codelens")

        -- NOTE: Navigation keymaps (gd, gD, gr, gI, gy) are defined in snacks.lua
        -- using Snacks.picker for better UX
      end,
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

        vim.keymap.set("i", "<Tab>", function()
          if not vim.lsp.inline_completion.get() then
            return "<Tab>"
          end
        end, { expr = true, desc = "Accept Copilot inline suggestion" })

        -- Toggle Copilot
        vim.keymap.set("n", "<leader>TC", function()
          local enabled = vim.lsp.inline_completion.is_enabled()
          vim.lsp.inline_completion.enable(not enabled)
          vim.notify("Copilot " .. (enabled and "disabled" or "enabled"), vim.log.levels.INFO)
        end, { desc = "Toggle Copilot" })
      end
    end)

    vim.diagnostic.config({
      severity_sort = true,
      signs = true,
      underline = false,
      virtual_text = {
        severity = vim.diagnostic.severity.ERROR,
      },
    })
  end,
}
