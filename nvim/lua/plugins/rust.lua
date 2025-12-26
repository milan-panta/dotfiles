-- Rust: rustaceanvim (manages rust-analyzer) + crates.nvim

return {
  {
    "mrcjkb/rustaceanvim",
    ft = "rust",
    opts = {
      tools = {
        hover_actions = { replace_builtin_hover = false },
      },
      server = {
        on_attach = function(_, bufnr)
          -- stylua: ignore start
          local map = function(keys, cmd, desc)
            vim.keymap.set("n", keys, cmd, { buffer = bufnr, desc = "Rust: " .. desc })
          end

          map("<leader>cr", function() vim.cmd.RustLsp("codeAction") end, "Code Action")
          map("<leader>cR", function() vim.cmd.RustLsp("runnables") end, "Runnables")
          map("<leader>ce", function() vim.cmd.RustLsp("explainError") end, "Explain Error")
          map("<leader>cE", function() vim.cmd.RustLsp("renderDiagnostic") end, "Render Diagnostic")
          map("<leader>cm", function() vim.cmd.RustLsp("expandMacro") end, "Expand Macro")
          map("<leader>cp", function() vim.cmd.RustLsp("parentModule") end, "Parent Module")
          map("<leader>co", function() vim.cmd.RustLsp("openDocs") end, "Open docs.rs")
          map("<leader>cC", function() vim.cmd.RustLsp("openCargo") end, "Open Cargo.toml")
          map("<leader>dr", function() vim.cmd.RustLsp("debuggables") end, "Debuggables")
          map("<leader>st", function() vim.cmd.RustLsp("testables") end, "Testables")
          map("K", function() vim.cmd.RustLsp({ "hover", "actions" }) end, "Hover Actions")
          -- stylua: ignore end
        end,
        default_settings = {
          ["rust-analyzer"] = {
            cargo = {
              allFeatures = true,
              loadOutDirsFromCheck = true,
              buildScripts = { enable = true },
            },
            checkOnSave = true,
            check = {
              command = "clippy",
              extraArgs = { "--no-deps" },
            },
            procMacro = {
              enable = true,
              ignored = {
                ["async-trait"] = { "async_trait" },
                ["napi-derive"] = { "napi" },
                ["async-recursion"] = { "async_recursion" },
              },
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
      -- Configure DAP adapter (codelldb) if installed via Mason
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

  {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = { crates = { enabled = true } },
      lsp = {
        enabled = true,
        actions = true,
        completion = true,
        hover = true,
      },
    },
  },
}
