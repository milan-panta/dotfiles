-- Formatting (conform) & Linting (nvim-lint)

return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ lsp_fallback = true, async = false, timeout_ms = 2000 })
          vim.cmd("w")
        end,
        mode = { "n", "v" },
        desc = "Format file/range",
      },
    },
    opts = function()
      local tools = require("config.tools")
      return {
        formatters_by_ft = tools.formatters_by_ft,
        format_on_save = function(bufnr)
          -- Disable with global or buffer-local variable
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          return { timeout_ms = 500, lsp_fallback = true }
        end,
      }
    end,
    init = function()
      -- Commands to toggle formatting
      vim.api.nvim_create_user_command("FormatDisable", function(args)
        if args.bang then
          vim.b.disable_autoformat = true
        else
          vim.g.disable_autoformat = true
        end
        vim.notify("Auto-format disabled", vim.log.levels.INFO)
      end, { bang = true, desc = "Disable autoformat (! for buffer only)" })

      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
        vim.notify("Auto-format enabled", vim.log.levels.INFO)
      end, { desc = "Enable autoformat" })
    end,
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local tools = require("config.tools")
      local lint = require("lint")
      lint.linters_by_ft = tools.linters_by_ft

      -- Run linting on these events
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
        callback = function()
          -- Only lint if buffer is modifiable
          if vim.bo.modifiable then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
