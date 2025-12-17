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
      -- copilot = {},
      cssls = {},
      eslint = {},
      hls = {},
      html = {},
      jsonls = {},
      marksman = {},
      rust_analyzer = {
      settings = {
        ["rust-analyzer"] = {
          cargo = {
            features = "all",
          },
          checkOnSave = {
            enable = true,
          },
          check = {
            command = "clippy",
          },
          imports = {
            group = {
              enable = false,
            },
          },
          completion = {
            postfix = {
              enable = false,
            },
          },
        },
      },
      },
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

        map("<Leader>wa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
        map("<Leader>wr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
        map("<Leader>wl", function()
          print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
        end, "List workspace folders")

        map("[e", function()
          vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
        end, "Previous Error")
        map("]e", function()
          vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
        end, "Next Error")

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if client and client.server_capabilities.inlayHintProvider then
          map("<Leader>ti", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
          end, "Toggle Inlay Hints")
        end
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
        vim.lsp.inline_completion.enable()
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
      end
    end)
  end,
}
