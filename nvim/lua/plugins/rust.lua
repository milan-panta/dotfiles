return {
  {
    "mrcjkb/rustaceanvim",
    ft = "rust",
    config = function()
      vim.g.rustaceanvim = {
        tools = {},
        server = {
          on_attach = function(_, bufnr)
            local wk = require("which-key")
            wk.add({
              {
                "<leader>cr",
                function()
                  vim.cmd.RustLsp("codeAction")
                end,
                desc = "Rust Code Action",
                buffer = bufnr,
              },
              {
                "<leader>dr",
                function()
                  vim.cmd.RustLsp("debuggables")
                end,
                desc = "Rust Debuggables",
                buffer = bufnr,
              },
              {
                "<leader>ce",
                function()
                  vim.cmd.RustLsp("explainError")
                end,
                desc = "Explain Error",
                buffer = bufnr,
              },
              {
                "<leader>cR",
                function()
                  vim.cmd.RustLsp("runnables")
                end,
                desc = "Rust Runnables",
                buffer = bufnr,
              },
              {
                "<leader>cm",
                function()
                  vim.cmd.RustLsp("expandMacro")
                end,
                desc = "Expand Macro",
                buffer = bufnr,
              },
              {
                "<leader>cp",
                function()
                  vim.cmd.RustLsp("parentModule")
                end,
                desc = "Parent Module",
                buffer = bufnr,
              },
              {
                "K",
                function()
                  vim.cmd.RustLsp({ "hover", "actions" })
                end,
                desc = "Hover Actions",
                buffer = bufnr,
              },
            })
          end,
          default_settings = {
            ["rust-analyzer"] = {
              cargo = {
                allFeatures = true,
                loadOutDirsFromCheck = true,
                buildScripts = {
                  enable = true,
                },
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
                lifetimeElisionHints = {
                  enable = "always",
                },
              },
            },
          },
        },
        dap = {},
      }
    end,
  },
  {
    "saecki/crates.nvim",
    event = { "BufRead Cargo.toml" },
    opts = {
      completion = {
        crates = { enabled = true },
      },
    },
  },
}
