return {
  "folke/persistence.nvim",
  event = "BufReadPre",
  opts = {
    -- add any custom options here
  },
  -- stylua: ignore
  keys = {
    { "<leader>qs", function() require("persistence").load() end, desc = "Restore Session" },
    { "<leader>qf", function() require("persistence").select() end, desc = "Search Sessions" },
    { "<leader>ql", function() require("persistence").load({ last = true }) end, desc = "Restore Last Session" },
    { "<leader>qd", function() require("persistence").stop() end, desc = "Don't Save Current Session" },
  },
}
