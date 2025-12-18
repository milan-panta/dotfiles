return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
    -- Adapters
    "nvim-neotest/neotest-python",
    "nvim-neotest/neotest-go",
    "rouge8/neotest-rust",
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
    { "<Leader>TM", function() require("neotest").run.run({ suite = true }) end, desc = "Run Suite" },
    { "[T", function() require("neotest").jump.prev({ status = "failed" }) end, desc = "Prev Failed Test" },
    { "]T", function() require("neotest").jump.next({ status = "failed" }) end, desc = "Next Failed Test" },
  },
  opts = {
    status = {
      virtual_text = true,
    },
    output = {
      open_on_run = true,
    },
    quickfix = {
      open = function()
        vim.cmd("copen")
      end,
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

    opts.adapters = {
      require("neotest-python")({
        dap = { justMyCode = false },
        args = { "--log-level", "DEBUG" },
        runner = "pytest",
      }),
      require("neotest-rust")({
        args = { "--no-capture" },
        dap_adapter = "codelldb",
      }),
    }

    require("neotest").setup(opts)
  end,
}
