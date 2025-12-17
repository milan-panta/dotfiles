return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "nvim-lua/plenary.nvim",
    "antoinemadec/FixCursorHold.nvim",
    "nvim-treesitter/nvim-treesitter",
    "nvim-neotest/neotest-python",
    "nvim-neotest/neotest-plenary",
    "alfaix/neotest-gtest",
  },
  keys = {
    { "<leader>Tt", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run File" },
    { "<leader>Tr", function() require("neotest").run.run() end, desc = "Run Nearest" },
    { "<leader>TT", function() require("neotest").run.run(vim.uv.cwd()) end, desc = "Run All Test Files" },
    { "<leader>Tl", function() require("neotest").run.run_last() end, desc = "Run Last" },
    { "<leader>Ts", function() require("neotest").summary.toggle() end, desc = "Toggle Summary" },
    { "<leader>To", function() require("neotest").output.open({ enter = true, auto_close = true }) end, desc = "Show Output" },
    { "<leader>TO", function() require("neotest").output_panel.toggle() end, desc = "Toggle Output Panel" },
    { "<leader>TS", function() require("neotest").run.stop() end, desc = "Stop" },
    { "<leader>Td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug Nearest" },
  },
  config = function()
    require("neotest").setup({
      adapters = {
        require("neotest-python")({
          dap = { justMyCode = false },
        }),
        require("neotest-plenary"),
        require("neotest-gtest").setup({}),
        require("rustaceanvim.neotest"),
      },
    })
  end,
}
