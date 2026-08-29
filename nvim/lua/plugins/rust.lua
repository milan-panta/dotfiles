return {
  {
    "mrcjkb/rustaceanvim",
    ft = "rust",
    opts = {
      tools = {
        hover_actions = { replace_builtin_hover = false },
      },
      dap = {
        -- Rustaceanvim uses the "lldb" adapter key for every executable
        -- adapter. Disable its LLDB-only setup while retaining Cargo-built
        -- debuggables and using GDB as the underlying DAP process.
        adapter = {
          type = "executable",
          command = "gdb",
          args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
          name = "gdb",
        },
        load_rust_types = false,
        auto_generate_source_map = false,
        add_dynamic_library_paths = false,
      },
      server = {
        on_attach = function(_, bufnr)
          -- stylua: ignore start
          local map = function(keys, cmd, desc)
            vim.keymap.set("n", keys, cmd, { buffer = bufnr, desc = "Rust: " .. desc })
          end

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
