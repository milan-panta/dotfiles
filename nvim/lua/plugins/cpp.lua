return {
  "p00f/clangd_extensions.nvim",
  ft = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
  opts = {
    inlay_hints = { inline = true },
    ast = {
      role_icons = {
        type = "",
        declaration = "",
        expression = "",
        specifier = "",
        statement = "",
        ["template argument"] = "",
      },
      kind_icons = {
        Compound = "",
        Recovery = "",
        TranslationUnit = "",
        PackExpansion = "",
        TemplateTypeParm = "",
        TemplateTemplateParm = "",
        TemplateParamObject = "",
      },
    },
  },
  config = function(_, opts)
    require("clangd_extensions").setup(opts)

    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("clangd_keymaps", { clear = true }),
      callback = function(event)
        local client = vim.lsp.get_client_by_id(event.data.client_id)
        if not client or client.name ~= "clangd" then
          return
        end

        if client.server_capabilities.inlayHintProvider then
          vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
        end

        local map = function(keys, cmd, desc)
          vim.keymap.set("n", keys, cmd, { buffer = event.buf, desc = "C/C++: " .. desc })
        end

        map("<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", "Switch Source/Header")
        map("<leader>ct", "<cmd>ClangdTypeHierarchy<cr>", "Type Hierarchy")
        map("<leader>cm", "<cmd>ClangdMemoryUsage<cr>", "Memory Usage")
        map("<leader>ci", "<cmd>ClangdSymbolInfo<cr>", "Symbol Info")
        map("<leader>cA", "<cmd>ClangdAST<cr>", "View AST")
      end,
    })
  end,
}
