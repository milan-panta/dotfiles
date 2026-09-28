return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" },
  dependencies = {
    { "mason-org/mason.nvim", config = true },
    "mason-org/mason-lspconfig.nvim",
  },
  config = function()
    local tools = require("config.tools")
    vim.diagnostic.config(tools.diagnostic_config)
    vim.diagnostic.enable(false)

    -- Shared capabilities for all LSP servers
    vim.lsp.config("*", {
      capabilities = tools.make_capabilities(),
    })

    -- Copilot: registered but NOT in automatic_enable — opt-in via <leader>ui
    vim.lsp.config("copilot", {
      handlers = {
        didChangeStatus = function(err, res)
          if err then
            return
          end
          if res.status == "Error" then
            vim.notify("Copilot: Please sign in with :LspCopilotSignIn", vim.log.levels.ERROR)
          end
        end,
      },
    })

    -- Per-server settings
    for name, opts in pairs(tools.servers) do
      vim.lsp.config(name, opts)
    end

    -- Enable only our explicit server list; Mason's bin dir is on PATH, and
    -- servers that aren't installed yet are skipped until their binary exists.
    -- Copilot is installed but NOT auto-enabled (toggled via <leader>ui)
    local server_names = tools.get_server_names()
    vim.lsp.enable(server_names)

    -- ensure_installed loads Mason's whole package registry (~50ms), so run
    -- it after the first buffer is drawn instead of while opening it.
    vim.schedule(function()
      require("mason-lspconfig").setup({
        ensure_installed = vim.list_extend(vim.deepcopy(server_names), { "copilot" }),
        automatic_enable = false,
      })
    end)

    for name, opts in pairs(tools.system_servers) do
      vim.lsp.config(name, opts)
      vim.lsp.enable(name)
    end

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("lsp_attach_keymaps", { clear = true }),
      callback = function(event)
        local map = function(keys, func, desc, mode)
          mode = mode or "n"
          vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
        end

        local client = vim.lsp.get_client_by_id(event.data.client_id)
        -- Keep semantic tokens for clangd (much better than treesitter for C++).
        -- Use the public toggle rather than mutating the server's capabilities.
        if client and client.name ~= "clangd" then
          vim.lsp.semantic_tokens.enable(false, { bufnr = event.buf, client_id = client.id })
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
      end,
    })

    vim.schedule(function()
      vim.lsp.inline_completion.enable(false) -- off by default, toggle with <leader>ui

      -- stylua: ignore start
      vim.keymap.set("i", "<C-y>", function()
        local ok, result = pcall(vim.lsp.inline_completion.get)
        if not ok or not result then
          vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-y>", true, false, true), "n", false)
        end
      end, { desc = "Accept inline suggestion" })

      vim.keymap.set({ "i", "n" }, "<M-]>", function() vim.lsp.inline_completion.select({ count = 1 }) end, { desc = "Next Copilot Suggestion" })
      vim.keymap.set({ "i", "n" }, "<M-[>", function() vim.lsp.inline_completion.select({ count = -1 }) end, { desc = "Prev Copilot Suggestion" })
      -- stylua: ignore end

      vim.keymap.set("n", "<leader>ui", function()
        local clients = vim.lsp.get_clients({ name = "copilot" })
        if #clients > 0 then
          vim.lsp.inline_completion.enable(false)
          for _, c in ipairs(clients) do
            c:stop()
          end
          vim.lsp.enable("copilot", false)
          vim.notify("Copilot disabled", vim.log.levels.INFO)
        else
          vim.lsp.enable("copilot")
          vim.lsp.inline_completion.enable(true)
          vim.notify("Copilot enabled", vim.log.levels.INFO)
        end
      end, { desc = "Toggle Copilot" })
    end)
  end,
}
