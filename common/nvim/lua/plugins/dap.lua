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
    "nvim-neotest/nvim-nio",
    "theHamsta/nvim-dap-virtual-text",
    { "jay-babu/mason-nvim-dap.nvim", dependencies = "mason-org/mason.nvim" },
  },
  -- stylua: ignore
  keys = {
    { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Breakpoint Condition" },
    { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
    { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
    { "<leader>dd", function() require("config.debug").build_and_debug() end, desc = "Build and Debug" },
    { "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
    { "<leader>dj", function() require("dap").down() end, desc = "Down Stack" },
    { "<leader>dk", function() require("dap").up() end, desc = "Up Stack" },
    { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
    { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
    { "<leader>dn", function() require("dap").step_over() end, desc = "Step Over" },
    { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
    { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
    { "<leader>ds", function() require("dap").session() end, desc = "Session" },
    { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
    { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
    { "<leader>du", function() require("dapui").toggle({}) end, desc = "Toggle DAP UI" },
    { "<leader>de", function() require("dapui").eval() end, desc = "Eval", mode = { "n", "v" } },
  },

  config = function()
    vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })
    for name, sign in pairs(dap_icons) do
      sign = type(sign) == "table" and sign or { sign }
      vim.fn.sign_define("Dap" .. name, {
        text = sign[1],
        texthl = sign[2] or "DiagnosticInfo",
        linehl = sign[3],
        numhl = sign[3],
      })
    end

    local dap = require("dap")
    local dapui = require("dapui")
    local debug = require("config.debug")

    dap.adapters.gdb = {
      type = "executable",
      command = "gdb",
      args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
    }

    dapui.setup({})

    require("nvim-dap-virtual-text").setup({
      commented = true,
    })

    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open({})
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close({})
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close({})
    end

    local tools = require("config.tools")
    require("mason-nvim-dap").setup({
      ensure_installed = tools.mason_dap_adapters,
      automatic_installation = true,
      handlers = {
        -- Do not let an accidentally installed CodeLLDB package inject LLDB
        -- launch configurations into this GDB-only setup.
        codelldb = function() end,
      },
    })

    -- Native-code launch configs for standalone files and project executables.
    dap.configurations.c = dap.configurations.c or {}
    dap.configurations.cpp = dap.configurations.cpp or {}
    dap.configurations.rust = dap.configurations.rust or {}
    local cpp_configs = {
      {
        name = "Launch executable",
        type = "gdb",
        request = "launch",
        program = function()
          return debug.prompt_executable()
        end,
        cwd = "${workspaceFolder}",
        stopAtBeginningOfMainSubprogram = false,
      },
      {
        name = "Launch with args",
        type = "gdb",
        request = "launch",
        program = function()
          return debug.prompt_executable()
        end,
        args = debug.prompt_args,
        cwd = "${workspaceFolder}",
        stopAtBeginningOfMainSubprogram = false,
      },
      {
        name = "Attach to process",
        type = "gdb",
        request = "attach",
        program = function()
          return debug.prompt_executable()
        end,
        pid = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
      },
      {
        name = "Open core dump",
        type = "gdb",
        request = "attach",
        program = debug.prompt_executable,
        coreFile = function()
          return vim.fn.input("Core file: ", vim.uv.cwd() .. "/core", "file")
        end,
        cwd = "${workspaceFolder}",
      },
      {
        name = "Attach to gdbserver",
        type = "gdb",
        request = "attach",
        target = function()
          return vim.fn.input("Target: ", "localhost:1234")
        end,
        program = debug.prompt_executable,
        cwd = "${workspaceFolder}",
      },
    }
    vim.list_extend(dap.configurations.c, cpp_configs)
    vim.list_extend(dap.configurations.cpp, cpp_configs)
    vim.list_extend(dap.configurations.rust, cpp_configs)
  end,
}
