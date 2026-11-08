local when_started = require("config.neotest_run").when_started
local run = require("config.neotest_run").run

-- Runs the whole project of the current file. neotest's own `suite` default picks
-- the first adapter, which can be the wrong language in a mixed project.
local function run_suite()
  when_started(function()
    local neotest = require("neotest")
    local adapter
    local file = vim.api.nvim_buf_get_name(0)
    for _, id in ipairs(neotest.state.adapter_ids()) do
      local tree = neotest.state.positions(id)
      if tree and tree:get_key(file) then
        adapter = id
        break
      end
    end
    neotest.run.run({ suite = true, adapter = adapter })
  end)
end

-- Watch mode needs the language server, which can still be starting right after a
-- file opens. Waits up to 10 seconds, then lets neotest report any problem itself.
local function toggle_watch()
  local buffer = vim.api.nvim_get_current_buf()
  local file = vim.api.nvim_buf_get_name(buffer)
  local attempts = 0
  local function try()
    attempts = attempts + 1
    if attempts >= 200 or #vim.lsp.get_clients({ bufnr = buffer, method = "textDocument/definition" }) > 0 then
      require("neotest").watch.toggle(file)
    else
      vim.defer_fn(try, 50)
    end
  end
  when_started(try)
end

return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/neotest-python",
    "fredrikaverpil/neotest-golang",
    "alfaix/neotest-gtest",
  },
  -- Load on open, not only on a keypress, so run buttons appear in Python files. Deferred
  -- until the file is on screen, so opening it doesn't wait for neotest.
  init = function()
    vim.api.nvim_create_autocmd("FileType", {
      pattern = "python",
      once = true,
      callback = function()
        vim.defer_fn(function()
          require("lazy").load({ plugins = { "neotest" } })
        end, 0)
      end,
    })
  end,
  -- stylua: ignore
  keys = {
    { "<leader>ta", function() require("neotest").run.attach() end, desc = "Attach to Test (Neotest)" },
    { "<leader>tf", function() run(vim.api.nvim_buf_get_name(0)) end, desc = "Run File (Neotest)" },
    { "<leader>tF", run_suite, desc = "Run All Test Files (Neotest)" },
    { "<leader>tr", function() run() end, desc = "Run Nearest (Neotest)" },
    { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run Last (Neotest)" },
    { "<leader>ts", function() when_started(function() require("neotest").summary.toggle() end) end, desc = "Toggle Summary (Neotest)" },
    { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output (Neotest)" },
    { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel (Neotest)" },
    { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop (Neotest)" },
    { "<leader>tw", toggle_watch, desc = "Toggle Watch (Neotest)" },
    { "<leader>td", function() run({ strategy = "dap" }) end, desc = "Debug Nearest" },
    { "<leader>tD", function() run({ vim.api.nvim_buf_get_name(0), strategy = "dap" }) end, desc = "Debug File" },
    { "[t", function() require("neotest").jump.prev({ status = "failed" }) end, desc = "Prev Failed Test" },
    { "]t", function() require("neotest").jump.next({ status = "failed" }) end, desc = "Next Failed Test" },
  },
  opts = {
    status = { virtual_text = false },
    output = { open_on_run = true },
    icons = { test = "▶" },
    consumers = {
      -- The client otherwise waits for the first run or summary call to discover tests.
      -- Scheduled so every other consumer is registered first; the summary panel
      -- stays on "No tests found" if it misses the client's "starting" event.
      autostart = function(client)
        client.listeners.started = function()
          require("config.neotest_run").mark_started()
        end
        -- Snacks' statuscolumn caches each line for 50 ms. Signs placed inside that window
        -- were drawn from the stale cache and stayed hidden until the next redraw.
        local function redraw_signs()
          vim.defer_fn(function()
            pcall(vim.api.nvim__redraw, { statuscolumn = true })
          end, 60)
        end
        client.listeners.discover_positions = redraw_signs
        client.listeners.results = redraw_signs
        vim.schedule(function()
          require("nio").run(function()
            client:get_adapters()
          end)
        end)
      end,
    },
    adapters = {
      ["neotest-python"] = {
        dap = {
          -- Keep the debugger out of neotest's own runner, which otherwise stops
          -- again on the SystemExit it raises after a failing test.
          rules = { { path = "**/neotest-python/**", include = false } },
        },
        args = { "--log-level", "INFO" },
        runner = "pytest",
        -- Prefers a .venv directly, because neotest-python caches its interpreter
        -- lookup and would miss a .venv created after the first discovery.
        python = function(root)
          local venv = root and root .. "/.venv/bin/python"
          if not vim.env.VIRTUAL_ENV and venv and vim.uv.fs_stat(venv) then
            return { venv }
          end
          return require("neotest-python.base").get_python_command(root)
        end,
      },
      ["rustaceanvim.neotest"] = {},
      -- "manual" uses this config with nvim-dap's delve adapter, instead of needing nvim-dap-go.
      ["neotest-golang"] = {
        dap_mode = "manual",
        dap_manual_config = { type = "delve", name = "Debug test", request = "launch", mode = "test" },
      },
      -- Default: only test_*.cpp and *_test.cpp files; restore this to limit discovery.
      -- ["neotest-gtest"] = { debug_adapter = "gdb" },
      ["neotest-gtest"] = {
        debug_adapter = "gdb",
        -- Same as the default root minus ".git", so a Python project in a repo
        -- that also holds C++ doesn't get the whole repo's .cpp files as tests.
        root = function(path)
          return require("neotest.lib").files.match_root_pattern(
            "compile_commands.json",
            "compile_flags.txt",
            "WORKSPACE",
            ".clangd",
            "build"
          )(path)
        end,
        -- Scan every .cpp file so embedded TEST macros are visible to Neotest.
        is_test_file = function(file)
          return file:match("%.cpp$") ~= nil
        end,
      },
    },
  },
  config = function(_, opts)
    local neotest_ns = vim.api.nvim_create_namespace("neotest")
    vim.diagnostic.config({
      virtual_text = {
        format = function(diagnostic)
          local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
          return message
        end,
      },
    }, neotest_ns)

    -- Builds an adapter from its module name and config, as lazy.nvim's neotest spec does.
    local function build(name, config)
      local adapter = require(name)
      if type(adapter) == "function" then
        adapter = adapter(config)
      elseif adapter.setup then
        adapter.setup(config)
      elseif adapter.adapter then
        adapter.adapter(config)
        adapter = adapter.adapter
      elseif getmetatable(adapter) and getmetatable(adapter).__call then
        adapter = adapter(config)
      end
      if name == "neotest-python" then
        adapter = require("config.neotest_python").wrap(adapter)
      end
      return adapter
    end

    -- Loading every adapter costs ~55ms each time neotest starts (neotest-gtest alone
    -- compiles a C++ query for ~37ms), even in a project of another language. These load
    -- the first time neotest asks about a folder or file of their project.
    local on_demand = {
      ["neotest-golang"] = { name = "neotest-golang", markers = { "go.mod", "go.work" }, ext = "%.go$" },
      ["rustaceanvim.neotest"] = { name = "rustaceanvim", markers = { "Cargo.toml" }, ext = "%.rs$" },
      ["neotest-gtest"] = {
        name = "neotest-gtest",
        markers = { "compile_commands.json", "compile_flags.txt", "WORKSPACE", ".clangd", "build" },
        ext = "%.c[cpx+]*$",
      },
    }
    local function lazy_adapter(module, config, spec)
      local real
      local function get()
        real = real or build(module, config)
        return real
      end
      local function in_project(path)
        return vim.fs.root(path, spec.markers) ~= nil
      end
      return setmetatable({
        name = spec.name,
        root = function(dir)
          return in_project(dir) and get().root(dir) or nil
        end,
        is_test_file = function(path)
          return path:match(spec.ext) ~= nil and in_project(path) and get().is_test_file(path)
        end,
      }, {
        __index = function(_, key)
          return get()[key]
        end,
      })
    end

    local adapters = {}
    for name, config in pairs(opts.adapters or {}) do
      if config ~= false then
        adapters[#adapters + 1] = on_demand[name] and lazy_adapter(name, config, on_demand[name]) or build(name, config)
      end
    end
    opts.adapters = adapters

    require("neotest").setup(opts)
  end,
}
