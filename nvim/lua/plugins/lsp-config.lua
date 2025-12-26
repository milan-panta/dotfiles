-- LSP: server setup and keymaps

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
        if client then
          client.server_capabilities.semanticTokensProvider = nil
        end

        -- Remove Nvim 0.11+ defaults (using Snacks.picker instead)
        pcall(vim.keymap.del, "n", "grn", { buffer = event.buf })
        pcall(vim.keymap.del, { "n", "x" }, "gra", { buffer = event.buf })
        pcall(vim.keymap.del, "n", "grr", { buffer = event.buf })
        pcall(vim.keymap.del, "n", "gri", { buffer = event.buf })
        pcall(vim.keymap.del, "n", "gO", { buffer = event.buf })
        pcall(vim.keymap.del, "i", "<C-S>", { buffer = event.buf })

        -- Documentation
        map("K", vim.lsp.buf.hover, "Hover Documentation")
        map("<C-k>", vim.lsp.buf.signature_help, "Signature Help", "i")

        -- Diagnostics (jump API is Nvim 0.11+)
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
        map("<C-W>d", vim.diagnostic.open_float, "Line Diagnostics")

        -- Actions
        map("<leader>rn", vim.lsp.buf.rename, "Rename")
        map("<leader>ca", vim.lsp.buf.code_action, "Code Action")
        map("<leader>ca", vim.lsp.buf.code_action, "Code Action", "x")
        map("<leader>cc", vim.lsp.codelens.run, "Run Codelens")
      end,
    })

    -- Nvim 0.12+ inline completion
    if vim.fn.has("nvim-0.12") == 1 then
      vim.schedule(function()
        vim.lsp.inline_completion.enable(false)

        vim.keymap.set({ "i", "n" }, "<M-]>", function()
          vim.lsp.inline_completion.select({ count = 1 })
        end, { desc = "Next inline suggestion" })

        vim.keymap.set({ "i", "n" }, "<M-[>", function()
          vim.lsp.inline_completion.select({ count = -1 })
        end, { desc = "Previous inline suggestion" })

        vim.keymap.set("i", "<Tab>", function()
          if not vim.lsp.inline_completion.get() then
            return "<Tab>"
          end
        end, { expr = true, desc = "Accept inline suggestion" })

        vim.keymap.set("n", "<leader>TC", function()
          local enabled = vim.lsp.inline_completion.is_enabled()
          vim.lsp.inline_completion.enable(not enabled)
          vim.notify("Inline completion " .. (enabled and "disabled" or "enabled"), vim.log.levels.INFO)
        end, { desc = "Toggle copilot suggestoins" })
      end)
    end
  end,
}
