local dap_icons = {
  Stopped = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
  Breakpoint = " ",
  BreakpointCondition = " ",
  BreakpointRejected = { " ", "DiagnosticError" },
  LogPoint = ".>",
}

return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "theHamsta/nvim-dap-virtual-text",
    "nvim-neotest/nvim-nio",
    "jay-babu/mason-nvim-dap.nvim",
    "williamboman/mason.nvim",
  },
  event = { "BufReadPost", "BufNewFile" },

  -- stylua: ignore
  keys = {
    { "<Leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end, desc = "Breakpoint Condition" },
    { "<Leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<Leader>dc", function() require("dap").continue() end, desc = "Run/Continue" },
    { "<Leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
    { "<Leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
    { "<Leader>di", function() require("dap").step_into() end, desc = "Step Into" },
    { "<Leader>dj", function() require("dap").down() end, desc = "Down" },
    { "<Leader>dk", function() require("dap").up() end, desc = "Up" },
    { "<Leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
    { "<Leader>do", function() require("dap").step_out() end, desc = "Step Out" },
    { "<Leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
    { "<Leader>dP", function() require("dap").pause() end, desc = "Pause" },
    { "<Leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
    { "<Leader>ds", function() require("dap").session() end, desc = "Session" },
    { "<Leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
    { "<Leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
    { "<Leader>du", function() require("dapui").toggle({ }) end, desc = "Dap UI" },
    { "<Leader>de", function() require("dapui").eval() end, desc = "Eval", mode = {"n", "v"} },

},

  config = function()
    vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

    for name, sign in pairs(dap_icons) do
      sign = type(sign) == "table" and sign or { sign }
      vim.fn.sign_define(
        "Dap" .. name,
        { text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
      )
    end

    local dap = require("dap")
    local dapui = require("dapui")
    dapui.setup()
    require("nvim-dap-virtual-text").setup()

    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open({})
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close({})
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close({})
    end

    -- debugging
    require("mason-nvim-dap").setup({
      handlers = {},
      ensure_installed = {
        "codelldb",
        "python",
      },
      automatic_installation = true,
    })
  end,
}
