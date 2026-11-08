local dap_icons = {
  Stopped = { "󰁕 ", "DiagnosticWarn", "DapStoppedLine" },
  Breakpoint = " ",
  BreakpointDisabled = { "○ ", "Comment" },
  BreakpointCondition = " ",
  BreakpointRejected = { " ", "DiagnosticError" },
  LogPoint = ".>",
}

return {
  "mfussenegger/nvim-dap",
  dependencies = {
    { "igorlfs/nvim-dap-view", version = "1.*" },
    { "jay-babu/mason-nvim-dap.nvim", dependencies = "mason-org/mason.nvim" },
  },
  init = function()
    -- Only files with saved breakpoints load the debug module (and nvim-dap) on open.
    local group = vim.api.nvim_create_augroup("dap_breakpoint_store", { clear = true })
    vim.api.nvim_create_autocmd("BufReadPost", {
      group = group,
      callback = function(event)
        if vim.uv.fs_stat(vim.fn.stdpath("state") .. "/dap-breakpoints.json") then
          require("config.breakpoints").restore_breakpoints(event.buf)
        end
      end,
    })
    -- Lines move as code is edited, so the saved lines are refreshed on save and on exit.
    vim.api.nvim_create_autocmd({ "BufWritePost", "VimLeavePre" }, {
      group = group,
      callback = function()
        if package.loaded["dap.breakpoints"] then
          require("config.breakpoints").save_breakpoints()
        end
      end,
    })
  end,
  -- stylua: ignore
  keys = {
    { "<leader>db", function() require("config.breakpoints").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<leader>dB", function() require("config.breakpoints").set_condition() end, desc = "Breakpoint: Condition" },
    { "<leader>dH", function() require("config.breakpoints").set_hit_count() end, desc = "Breakpoint: Hit Count" },
    { "<leader>dL", function() require("config.breakpoints").set_log_message() end, desc = "Breakpoint: Log Message (no stop)" },
    { "<leader>dX", function() require("config.breakpoints").toggle_enabled() end, desc = "Breakpoint: Disable or Enable" },
    { "<leader>da", function() require("config.debug").jump("breakpoints") end, desc = "All Breakpoints" },
    { "<leader>dc", function() require("config.debug").debug_this() end, desc = "Debug This, or Continue" },
    { "<F5>", function() require("config.debug").debug_this() end, desc = "Debug This, or Continue" },
    { "<leader>dD", function() require("dap").continue({ new = true }) end, desc = "Debug With… (project configs, launch.json, attach)" },
    { "<leader>dI", function() require("config.debug").debug_with_input() end, desc = "Debug With Input…" },
    { "<leader>dO", function() require("config.debug").focus_console() end, desc = "Jump to Program Console" },
    { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
    { "<leader>dd", function() require("config.debug").debug_this() end, desc = "Debug This, or Continue" },
    { "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (No Execute)" },
    { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
    { "<leader>dj", function() require("dap").down() end, desc = "Down Stack" },
    { "<leader>dk", function() require("dap").up() end, desc = "Up Stack" },
    { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
    { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
    { "<leader>dn", function() require("dap").step_over() end, desc = "Step Over" },
    { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
    { "<leader>dr", function() require("config.debug").jump("repl") end, desc = "Jump to REPL" },
    { "<leader>ds", function() require("config.debug").jump("scopes") end, desc = "Jump to Variables" },
    { "<leader>dt", function() require("config.debug").stop() end, desc = "Stop" },
    { "<leader>dR", function() require("config.debug").restart() end, desc = "Restart" },
    { "<leader>dS", function() require("dap").step_into({ askForTargets = true }) end, desc = "Step Into Chosen Call" },
    { "<leader>dw", function() require("config.debug").watch() end, desc = "Watch Word or Selection", mode = { "n", "x" } },
    { "<leader>de", "<cmd>DapViewHover<cr>", desc = "Evaluate Word or Selection", mode = { "n", "x" } },
    { "<leader>dx", function() require("config.debug").exception_stops() end, desc = "Exception Stops: raised, uncaught…" },
    { "<leader>dJ", function() require("config.debug").toggle_just_my_code() end, desc = "Toggle Just My Code" },
    { "<F9>", function() require("config.breakpoints").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
    { "<F10>", function() require("dap").step_over() end, desc = "Step Over" },
    { "<F11>", function() require("dap").step_into() end, desc = "Step Into" },
    { "<S-F11>", function() require("dap").step_out() end, desc = "Step Out" },
    { "<S-F5>", function() require("config.debug").stop() end, desc = "Stop" },
    { "<F23>", function() require("dap").step_out() end, desc = "Step Out" }, -- how some terminals send S-F11
    { "<F17>", function() require("config.debug").stop() end, desc = "Stop" }, -- how some terminals send S-F5
    { "<leader>du", function() require("dap-view").toggle(true) end, desc = "Toggle Debug View" },
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
    local debug = require("config.debug")

    -- A function, because a program's stdin is set up with gdb's options for that run.
    dap.adapters.gdb = function(callback, config)
      callback({ type = "executable", command = "gdb", args = debug.gdb_args(config) })
    end

    -- pytest catches test failures, so debugpy's default "uncaught" filter never
    -- fires for them. "userUnhandled" stops on the line that raised in your code.
    dap.defaults.python.exception_breakpoints = { "userUnhandled" }
    dap.defaults.debugpy.exception_breakpoints = { "userUnhandled" }

    require("dap-view").setup({
      winbar = {
        sections = { "scopes", "watches", "repl", "threads", "breakpoints", "exceptions" },
        default_section = "scopes",
        controls = { enabled = true },
      },
      windows = { size = 0.3, position = "below", terminal = { position = "right", size = 0.4 } },
      virtual_text = { enabled = true },
      switchbuf = "useopen,uselast",
    })
    -- gdb's register list would bury the locals; one key still opens it.
    require("dap-view.state").collapsed_scopes = { "Registers" }

    -- dap-view starts each adapter on the adapter's own exception defaults, then applies
    -- them after configurationDone, which would replace dap.defaults.*.exception_breakpoints.
    -- Start it on ours instead. The Exceptions tab can still change them for this Neovim.
    local seeded = {}
    local function seed_exception_filters(session)
      local adapter = session.config.type
      local options = require("dap-view.state").exceptions_options[adapter]
      local wanted = dap.defaults[adapter].exception_breakpoints
      if seeded[adapter] or not options or type(wanted) ~= "table" then
        return
      end
      seeded[adapter] = true
      for _, option in ipairs(options) do
        option.enabled = vim.tbl_contains(wanted, option.exception_filter.filter)
      end
    end

    -- The view opens with a session and stays after it ends, so the final output can be
    -- read. <leader>du or q closes it.
    dap.listeners.after.event_initialized["config_debug"] = function(session)
      seed_exception_filters(session)
      require("dap-view").open()
    end
    -- A change in the Exceptions tab applies once the program is already running. Keep it
    -- for the next session too, where it's sent before any code runs.
    dap.listeners.after.setExceptionBreakpoints["config_debug"] = function(session, err, _, request)
      if not err and request and request.filters then
        dap.defaults[session.config.type].exception_breakpoints = request.filters
      end
    end
    dap.listeners.on_config["config_debug"] = debug.apply_just_my_code
    dap.listeners.after.event_stopped["config_debug"] = debug.on_stopped
    dap.listeners.after.event_exited["config_debug"] = function(_, body)
      vim.notify(
        "Program exited with code " .. tostring(body and body.exitCode),
        vim.log.levels.INFO,
        { title = "Debug" }
      )
    end
    -- Logpoints, and the output of programs with no terminal of their own, are in the REPL tab.
    dap.listeners.after.event_terminated["config_debug"] = function()
      -- DapViewShow jumps when the tab is already showing; keep the cursor where it was.
      local win = vim.api.nvim_get_current_win()
      pcall(vim.cmd.DapViewShow, "repl")
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
      end
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("dap_view_q", { clear = true }),
      pattern = { "dap-view", "dap-view-term", "dap-repl" },
      callback = function(event)
        vim.keymap.set(
          "n",
          "q",
          "<cmd>DapViewClose!<cr>",
          { buf = event.buf, nowait = true, desc = "Close Debug View" }
        )
      end,
    })

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

    -- Haskell: hdb listens on a port nvim-dap picks.
    dap.adapters.haskell = {
      type = "server",
      port = "${port}",
      executable = { command = "hdb", args = { "server", "--port", "${port}", "--internal-interpreter" } },
    }

    -- launch.json names these types differently from Mason's adapters.
    dap.adapters.python = debug.python_adapter(dap.adapters.python)
    dap.adapters.debugpy = dap.adapters.python
    require("dap.ext.vscode").type_to_filetypes.debugpy = { "python" }
    require("dap.ext.vscode").type_to_filetypes.delve = { "go" }

    dap.configurations.python = dap.configurations.python or {}
    vim.list_extend(dap.configurations.python, {
      {
        name = "This file, with args",
        type = "python",
        request = "launch",
        program = "${file}",
        args = debug.prompt_args,
        console = "integratedTerminal",
        python = function()
          return { debug.python_for(vim.api.nvim_buf_get_name(0)) }
        end,
      },
      {
        name = "Attach to port",
        type = "python",
        request = "attach",
        connect = function()
          return { host = "127.0.0.1", port = tonumber(vim.fn.input("Port: ", "5678")) }
        end,
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
          return require("config.build").prompt_executable()
        end,
        cwd = "${workspaceFolder}",
        stopAtBeginningOfMainSubprogram = false,
      },
      {
        name = "Launch with args",
        type = "gdb",
        request = "launch",
        program = function()
          return require("config.build").prompt_executable()
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
          return require("config.build").prompt_executable()
        end,
        pid = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}",
      },
      {
        name = "Open core dump",
        type = "gdb",
        request = "attach",
        program = require("config.build").prompt_executable,
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
        program = require("config.build").prompt_executable,
        cwd = "${workspaceFolder}",
      },
    }
    vim.list_extend(dap.configurations.c, cpp_configs)
    vim.list_extend(dap.configurations.cpp, cpp_configs)
    vim.list_extend(dap.configurations.rust, cpp_configs)
  end,
}
