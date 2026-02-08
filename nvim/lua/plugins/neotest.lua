return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/neotest-python",
    "rcasia/neotest-java",
    "fredrikaverpil/neotest-golang",
    "alfaix/neotest-gtest",
  },
  -- stylua: ignore
  keys = {
    { "<leader>ta", function() require("neotest").run.attach() end, desc = "Attach to Test (Neotest)" },
    { "<leader>tt", function() require("neotest").run.run(vim.api.nvim_buf_get_name(0)) end, desc = "Run File (Neotest)" },
    { "<leader>tT", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run All Test Files (Neotest)" },
    { "<leader>tr", function() require("neotest").run.run() end, desc = "Run Nearest (Neotest)" },
    { "<leader>tl", function() require("neotest").run.run_last() end, desc = "Run Last (Neotest)" },
    { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Toggle Summary (Neotest)" },
    { "<leader>to", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output (Neotest)" },
    { "<leader>tO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel (Neotest)" },
    { "<leader>tS", function() require("neotest").run.stop() end, desc = "Stop (Neotest)" },
    { "<leader>tw", function() require("neotest").watch.toggle(vim.api.nvim_buf_get_name(0)) end, desc = "Toggle Watch (Neotest)" },
    { "<leader>td", function() require("neotest").run.run({strategy = "dap"}) end, desc = "Debug Nearest" },
    { "<leader>tD", function() require("neotest").run.run({ vim.api.nvim_buf_get_name(0), strategy = "dap" }) end, desc = "Debug File" },
    { "[t", function() require("neotest").jump.prev({ status = "failed" }) end, desc = "Prev Failed Test" },
    { "]t", function() require("neotest").jump.next({ status = "failed" }) end, desc = "Next Failed Test" },
  },
  opts = {
    status = { virtual_text = true },
    output = { open_on_run = true },
    adapters = {
      ["neotest-python"] = {
        dap = { justMyCode = false },
        args = { "--log-level", "INFO" },
        runner = "pytest",
      },
      ["rustaceanvim.neotest"] = {},
      ["neotest-java"] = {},
      ["neotest-golang"] = {},
      ["neotest-gtest"] = {},
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

    if opts.adapters then
      local adapters = {}
      for name, config in pairs(opts.adapters) do
        if type(name) == "number" then
          if type(config) == "string" then
            config = require(config)
          end
          adapters[#adapters + 1] = config
        elseif config ~= false then
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
          adapters[#adapters + 1] = adapter
        end
      end
      opts.adapters = adapters
    end

    require("neotest").setup(opts)
  end,
}
