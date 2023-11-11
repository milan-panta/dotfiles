return {
  "mfussenegger/nvim-dap",
  keys = {
    {
      "<Leader>db",
      function()
        vim.cmd("DapToggleBreakpoint")
      end,
      desc = "Toggle breakpoint",
    },
    {
      "<Leader>dc",
      function()
        require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end,
      desc = "Toggle conditional breakpoint",
    },
    {
      "<Leader>dl",
      function()
        require("dap").set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
      end,
      desc = "Toggle breakpoint with log",
    },
  },
  dependencies = {
    {
      "rcarriga/nvim-dap-ui",
      dependencies = "mfussenegger/nvim-dap",
    },
    {
      "mfussenegger/nvim-dap-python",
      config = function()
        local path = "~/.local/share/nvim/mason/packages/debugpy/venv/bin/python"
        require("dap-python").setup(path)
      end,
    },
    {
      "jay-babu/mason-nvim-dap.nvim",
    },
    {
      "LiadOz/nvim-dap-repl-highlights",
      opts = {},
    },
    {
      "theHamsta/nvim-dap-virtual-text",
      config = function()
        require("nvim-dap-virtual-text").setup({
          -- virt_text_pos = vim.fn.has("nvim-0.10") == 1 and "inline" or "eol",
          virt_text_pos = "eol",
        })
      end,
    },
  },
  config = function()
    -- debugging
    require("mason-nvim-dap").setup({
      handlers = {},
      ensure_installed = { --[[ "python", ]]
        "codelldb",
      },
      automatic_installation = true,
    })
    vim.keymap.set("n", "<F5>", function()
      require("dap").continue()
    end, { desc = "Continue debugging" })
    vim.keymap.set("n", "<F3>", function()
      require("dap").step_into()
    end, { desc = "Step into" })
    vim.keymap.set("n", "<F9>", function()
      require("dap").terminate()
    end, { desc = "Terminate debugging" })
    vim.keymap.set("n", "<F4>", function()
      require("dap").step_over()
    end, { desc = "Step over" })
    vim.keymap.set("n", "<F12>", function()
      require("dap").step_out()
    end, { desc = "Step out" })
    vim.keymap.set("n", "<F6>", function()
      require("dap").repl.open()
    end, { desc = "Open new debuging repl" })
    vim.keymap.set("n", "<Leader>dp", function()
      require("dap-python").test_method()
    end, { desc = "Start Python Debugging" })

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
