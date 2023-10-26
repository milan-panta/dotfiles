return {
  "mfussenegger/nvim-dap",
  keys = {
    {
      "<Leader>db",
      function()
        vim.cmd("DapToggleBreakpoint")
      end,
      desc = "Toggle Breakpoint",
    },
  },
  dependencies = {
    {
      "rcarriga/nvim-dap-ui",
      dependencies = "mfussenegger/nvim-dap",
    },
    {
      "mfussenegger/nvim-dap-python",
      dependencies = {
        "mfussenegger/nvim-dap",
        "rcarriga/nvim-dap-ui",
      },
      config = function()
        local path = "~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"
        require("dap-python").setup(path)
        vim.keymap.set("n", "<Leader>dp", function()
          require("dap-python").test_method()
        end, { desc = "Start Python Debugging" })
      end,
    },
    {
      "jay-babu/mason-nvim-dap.nvim",
    },
  },
  config = function()
    -- debugging
    require("mason-nvim-dap").setup({
      ensure_installed = { "python" },
      automatic_installation = true,
    })

    local dap = require("dap")
    local dapui = require("dapui")
    dapui.setup()
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end
  end,
}
