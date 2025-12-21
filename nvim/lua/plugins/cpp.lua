local clangd_ext_opts = {
  inlay_hints = {
    inline = true,
  },
  ast = {
    role_icons = {
      type = "",
      declaration = "",
      expression = "",
      specifier = "",
      statement = "",
      ["template argument"] = "",
    },
    kind_icons = {
      Compound = "",
      Recovery = "",
      TranslationUnit = "",
      PackExpansion = "",
      TemplateTypeParm = "",
      TemplateTemplateParm = "",
      TemplateParamObject = "",
    },
  },
}

return {
  {
    "p00f/clangd_extensions.nvim",
    lazy = true,
    ft = { "c", "cpp", "objc", "objcpp", "cuda", "proto" },
    config = function()
      require("clangd_extensions").setup(clangd_ext_opts)

      -- Setup keymaps and features when clangd attaches
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("clangd_extensions", { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client.name == "clangd" then
            -- Enable inlay hints if available
            if client.server_capabilities.inlayHintProvider then
              vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
            end

            local map = function(keys, func, desc)
              vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
            end

            map("<leader>ch", "<cmd>ClangdSwitchSourceHeader<cr>", "Switch Source/Header")
            map("<leader>ct", "<cmd>ClangdTypeHierarchy<cr>", "Type Hierarchy")
            map("<leader>cm", "<cmd>ClangdMemoryUsage<cr>", "Memory Usage")
            map("<leader>ci", "<cmd>ClangdSymbolInfo<cr>", "Symbol Info")
            map("<leader>cA", "<cmd>ClangdAST<cr>", "View AST")
          end
        end,
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          root_dir = function(fname)
            return require("lspconfig.util").root_pattern(
              "Makefile",
              "configure.ac",
              "configure.in",
              "config.h.in",
              "meson.build",
              "opt/build/ninja.build",
              "build.ninja"
            )(fname) or require("lspconfig.util").root_pattern("compile_commands.json", "compile_flags.txt")(
              fname
            ) or vim.fs.dirname(vim.fs.find(".git", { path = fname, upward = true })[1])
          end,
          capabilities = {
            offsetEncoding = { "utf-16" },
          },
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--header-insertion=iwyu",
            "--completion-style=detailed",
            "--function-arg-placeholders",
            "--fallback-style=llvm",
          },
          init_options = {
            usePlaceholders = true,
            completeUnimported = true,
            clangdFileStatus = true,
          },
        },
      },
    },
  },
}
