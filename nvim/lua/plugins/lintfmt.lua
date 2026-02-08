return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({
            lsp_format = "fallback",
            async = true,
            timeout_ms = 2000,
          }, function()
            vim.cmd.write()
          end)
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
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          return { timeout_ms = 1000, lsp_format = "fallback" }
        end,
      }
    end,
    init = function()
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

      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        group = vim.api.nvim_create_augroup("nvim_lint", { clear = true }),
        callback = function()
          if vim.bo.modifiable then
            lint.try_lint()
          end
        end,
      })
    end,
  },
}
