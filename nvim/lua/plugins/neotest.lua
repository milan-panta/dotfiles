return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    -- Adapters
    "nvim-neotest/neotest-python",
    "nvim-neotest/neotest-go",
  },
  -- stylua: ignore
  keys = {
    { "<leader>Ta", function() require("neotest").run.attach() end, desc = "Attach to Test (Neotest)" },
    { "<leader>Tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File (Neotest)" },
    { "<leader>TT", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run All Test Files (Neotest)" },
    { "<leader>Tr", function() require("neotest").run.run() end, desc = "Run Nearest (Neotest)" },
    { "<leader>Tl", function() require("neotest").run.run_last() end, desc = "Run Last (Neotest)" },
    { "<leader>Ts", function() require("neotest").summary.toggle() end, desc = "Toggle Summary (Neotest)" },
    { "<leader>To", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output (Neotest)" },
    { "<leader>TO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel (Neotest)" },
    { "<leader>TS", function() require("neotest").run.stop() end, desc = "Stop (Neotest)" },
    { "<leader>Tw", function() require("neotest").watch.toggle(vim.fn.expand("%")) end, desc = "Toggle Watch (Neotest)" },
    { "<leader>Td", function() require("neotest").run.run({strategy = "dap"}) end, desc = "Debug Nearest" },
    { "<Leader>TD", function() require("neotest").run.run({ vim.fn.expand("%"), strategy = "dap" }) end, desc = "Debug File" },
    { "[T", function() require("neotest").jump.prev({ status = "failed" }) end, desc = "Prev Failed Test" },
    { "]T", function() require("neotest").jump.next({ status = "failed" }) end, desc = "Next Failed Test" },
  },
  opts = {
    status = { virtual_text = true },
    output = { open_on_run = true },
    adapters = {
      -- Use table format for lazy loading of adapters
      ["neotest-python"] = {
        dap = { justMyCode = false },
        args = { "--log-level", "DEBUG" },
        runner = "pytest",
      },
      -- rustaceanvim provides its own neotest adapter
      ["rustaceanvim.neotest"] = {},
    },
  },
  config = function(_, opts)
    local neotest_ns = vim.api.nvim_create_namespace("neotest")
    vim.diagnostic.config({
      virtual_text = {
        format = function(diagnostic)
          -- Replace newline and tab characters with space for more compact diagnostics
          local message = diagnostic.message:gsub("\n", " "):gsub("\t", " "):gsub("%s+", " "):gsub("^%s+", "")
          return message
        end,
      },
    }, neotest_ns)

    -- Process adapters from opts.adapters table
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
          if type(config) == "table" and not vim.tbl_isempty(config) then
            local meta = getmetatable(adapter)
            if adapter.setup then
              adapter.setup(config)
            elseif adapter.adapter then
              adapter.adapter(config)
              adapter = adapter.adapter
            elseif meta and meta.__call then
              adapter = adapter(config)
            else
              error("Adapter " .. name .. " does not support setup")
            end
          end
          adapters[#adapters + 1] = adapter
        end
      end
      opts.adapters = adapters
    end

    require("neotest").setup(opts)
  end,
}
