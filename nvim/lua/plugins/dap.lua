return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "theHamsta/nvim-dap-virtual-text",
      "nvim-neotest/nvim-nio",
      "jay-babu/mason-nvim-dap.nvim",
      "williamboman/mason.nvim",
    },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      dapui.setup()
      require("nvim-dap-virtual-text").setup()

      -- debugging
      require("mason-nvim-dap").setup({
        handlers = {},
        ensure_installed = {
          "codelldb",
          "python",
        },
        automatic_installation = true,
      })

      -- Key mappings
      vim.keymap.set("n", "<leader>b", dap.toggle_breakpoint)
      vim.keymap.set("n", "<leader>B", function()
        require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end)

      vim.keymap.set("n", "<leader>gb", dap.run_to_cursor)
      vim.keymap.set("n", "<leader>?", function()
        require("dapui").eval()
      end)
      vim.keymap.set("n", "<leader>dt", function()
        require("dapui").toggle()
      end)
      vim.keymap.set("n", "<F1>", dap.continue)
      vim.keymap.set("n", "<F2>", dap.step_into)
      vim.keymap.set("n", "<F3>", dap.step_over)
      vim.keymap.set("n", "<F4>", dap.step_out)
      vim.keymap.set("n", "<F5>", dap.step_back)
      vim.keymap.set("n", "<F10>", dap.restart)
    end,
  },
}
