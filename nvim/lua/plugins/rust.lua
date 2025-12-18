return {
  {
    "mrcjkb/rustaceanvim",
    ft = "rust",
    opts = {
      server = {
        on_attach = function(_, bufnr)
          local wk = require("which-key")
          -- stylua: ignore start
          wk.add({
            { "<leader>cr", function() vim.cmd.RustLsp("codeAction") end, desc = "Code Action (Rust)", buffer = bufnr },
            { "<leader>cR", function() vim.cmd.RustLsp("runnables") end, desc = "Runnables", buffer = bufnr },
            { "<leader>ce", function() vim.cmd.RustLsp("explainError") end, desc = "Explain Error", buffer = bufnr },
            { "<leader>cE", function() vim.cmd.RustLsp("renderDiagnostic") end, desc = "Render Diagnostic", buffer = bufnr },
            { "<leader>cm", function() vim.cmd.RustLsp("expandMacro") end, desc = "Expand Macro", buffer = bufnr },
            { "<leader>cp", function() vim.cmd.RustLsp("parentModule") end, desc = "Parent Module", buffer = bufnr },
            { "<leader>co", function() vim.cmd.RustLsp("openDocs") end, desc = "Open docs.rs", buffer = bufnr },
            { "<leader>cC", function() vim.cmd.RustLsp("openCargo") end, desc = "Open Cargo.toml", buffer = bufnr },
            { "<leader>dr", function() vim.cmd.RustLsp("debuggables") end, desc = "Debuggables", buffer = bufnr },
            { "K", function() vim.cmd.RustLsp({ "hover", "actions" }) end, desc = "Hover Actions", buffer = bufnr },
          })
        end,
        default_settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              buildScripts = { enable = true },
            },
            checkOnSave = false,
            procMacro = {
              enable = true,
              ignored = {
                ["async-trait"] = { "async_trait" },
                ["napi-derive"] = { "napi" },
                ["async-recursion"] = { "async_recursion" },
              },
            },
            inlayHints = {
              lifetimeElisionHints = { enable = "always" },
            },
            files = {
              excludeDirs = {
                ".direnv",
                ".git",
                ".github",
                ".gitlab",
                ".jj",
                "bin",
                "node_modules",
                "target",
                "venv",
                ".venv",
              },
            },
          },
        },
      },
    },
    config = function(_, opts)
      -- Setup codelldb DAP adapter from mason
      local mason_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/"
      local codelldb_path = mason_path .. "adapter/codelldb"
      local liblldb_path = mason_path .. "lldb/lib/liblldb.dylib"
      if vim.uv.fs_stat(codelldb_path) and vim.uv.fs_stat(liblldb_path) then
        opts.dap = {
          adapter = require("rustaceanvim.config").get_codelldb_adapter(codelldb_path, liblldb_path),
        }
      end
      vim.g.rustaceanvim = vim.tbl_deep_extend("keep", vim.g.rustaceanvim or {}, opts or {})
    end,
  },

  -- Cargo.toml integration
  {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        crates = { enabled = true },
      },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },
}
