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
      local ui = require("dapui")
      require("dapui").setup()
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

      -- Configure codelldb for c/cpp
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
          args = { "--port", "${port}" },
        },
      }

      -- Configure C/C++ debugging
      dap.configurations.cpp = {
        {
          name = "Launch file",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }
      dap.configurations.c = dap.configurations.cpp

      -- Key mappings
      vim.keymap.set("n", "<space>b", dap.toggle_breakpoint)
      vim.keymap.set("n", "<space>gb", dap.run_to_cursor)
      vim.keymap.set("n", "<space>?", function()
        require("dapui").eval(nil, { enter = true })
      end)
      vim.keymap.set("n", "<F3>", dap.continue)
      vim.keymap.set("n", "<F4>", dap.step_into)
      vim.keymap.set("n", "<F5>", dap.step_over)
      vim.keymap.set("n", "<F6>", dap.step_out)
      vim.keymap.set("n", "<F7>", dap.step_back)
      vim.keymap.set("n", "<F12>", dap.restart)

      -- DAP UI configuration
      dap.listeners.before.attach.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        ui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        ui.close()
      end
    end,
  },
}
