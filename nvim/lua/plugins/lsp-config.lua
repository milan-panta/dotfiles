return {
  "neovim/nvim-lspconfig",
  event = "VeryLazy",
  dependencies = {
    { "williamboman/mason.nvim", config = true },
    "williamboman/mason-lspconfig.nvim",
    "saghen/blink.cmp",
  },
  config = function()
    local tools = require("config.tools")
    vim.diagnostic.config(tools.diagnostic_config)

    require("mason-lspconfig").setup({
      ensure_installed = tools.get_server_names(),
      handlers = {
        function(server_name)
          local server_opts = vim.deepcopy(tools.servers[server_name] or {})
          server_opts.capabilities = tools.make_capabilities(server_opts)
          require("lspconfig")[server_name].setup(server_opts)
        end,

        ["copilot"] = function()
          local server_opts = vim.deepcopy(tools.servers.copilot or {})
          server_opts.capabilities = tools.make_capabilities(server_opts)
          server_opts.handlers = {
            didChangeStatus = function(err, res)
              if err then
                return
              end
              if res.status == "Error" then
                vim.notify("Copilot: Please sign in with :LspCopilotSignIn", vim.log.levels.ERROR)
              end
            end,
          }
          require("lspconfig").copilot.setup(server_opts)
        end,

        ["rust_analyzer"] = function() end, -- handled by rustaceanvim
      },
    })

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp_attach_keymaps", { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or "n"
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        -- Keep semantic tokens for clangd (much better than treesitter for C++)
        if client and client.name ~= "clangd" then
          client.server_capabilities.semanticTokensProvider = nil
        end

        -- Remove Nvim 0.11+ defaults (using Snacks.picker instead)
        pcall(vim.keymap.del, "n", "grn", { buffer = event.buf })
        pcall(vim.keymap.del, { "n", "x" }, "gra", { buffer = event.buf })
        pcall(vim.keymap.del, "n", "grr", { buffer = event.buf })
        pcall(vim.keymap.del, "n", "gri", { buffer = event.buf })
        pcall(vim.keymap.del, "n", "gO", { buffer = event.buf })
        pcall(vim.keymap.del, "i", "<C-S>", { buffer = event.buf })

        map("K", vim.lsp.buf.hover, "Hover Documentation")
        map("<C-k>", vim.lsp.buf.signature_help, "Signature Help", "i")

        map("[d", function()
          vim.diagnostic.jump({ count = -1 })
        end, "Previous Diagnostic")
        map("]d", function()
          vim.diagnostic.jump({ count = 1 })
        end, "Next Diagnostic")
        map("[e", function()
          vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR })
        end, "Previous Error")
        map("]e", function()
          vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR })
        end, "Next Error")
        map("<C-s>", vim.diagnostic.open_float, "Line Diagnostics")

        map("cd", vim.lsp.buf.rename, "Rename")
        map("g.", vim.lsp.buf.code_action, "Code Action")
        map("g.", vim.lsp.buf.code_action, "Code Action", "x")
        map("<leader>cc", vim.lsp.codelens.run, "Run Codelens")

        if client and client:supports_method("textDocument/codeLens") then
          vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
            buffer = event.buf,
            callback = function()
              if vim.g.codelens_enabled ~= false then
                vim.lsp.codelens.enable(true, { bufnr = event.buf })
              end
            end,
          })
          if vim.g.codelens_enabled ~= false then
            vim.lsp.codelens.enable(true, { bufnr = event.buf })
          end
        end
      end,
    })

    vim.schedule(function()
      vim.lsp.inline_completion.enable(false) -- off by default, toggle with <leader>ui

      -- stylua: ignore start
      vim.keymap.set("i", "<Tab>", function()
        local ok, result = pcall(vim.lsp.inline_completion.get)
        if not ok or not result then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Tab>", true, false, true), "n", false)
        end
      end, { desc = "Accept inline suggestion" })

      vim.keymap.set({ "i", "n" }, "<M-]>", function() vim.lsp.inline_completion.select({ count = 1 }) end, { desc = "Next Copilot Suggestion" })
      vim.keymap.set({ "i", "n" }, "<M-[>", function() vim.lsp.inline_completion.select({ count = -1 }) end, { desc = "Prev Copilot Suggestion" })
      -- stylua: ignore end

      vim.keymap.set("n", "<leader>ui", function()
        local enabled = vim.lsp.inline_completion.is_enabled()
        vim.lsp.inline_completion.enable(not enabled)
        vim.notify("Inline completion " .. (enabled and "disabled" or "enabled"), vim.log.levels.INFO)
      end, { desc = "Toggle inline completion" })
    end)
  end,
}
