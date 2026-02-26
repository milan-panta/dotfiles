return {
  "esmuellert/codediff.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  cmd = "CodeDiff",
  keys = {
    { "<leader>gd", "<cmd>CodeDiff<cr>", desc = "Diff this" },
    {
      "<leader>gD",
      function()
        vim.ui.input({ prompt = "Diff against revision: " }, function(input)
          if input then
            vim.cmd("CodeDiff " .. input)
          end
        end)
      end,
      desc = "Diff against revision",
    },
    { "<leader>gp", "<cmd>CodeDiff main...<cr>", desc = "PR diff (vs main)" },
    { "<leader>gh", "<cmd>CodeDiff history<cr>", desc = "Show git history" },
    { "<leader>gH", "<cmd>CodeDiff history %<cr>", desc = "File history" },
    { "<leader>gc", "<cmd>CodeDiff history --base WORKING<cr>", desc = "Diff repo vs picked commit" },
    { "<leader>gC", "<cmd>CodeDiff history --base WORKING %<cr>", desc = "Diff file vs picked commit" },
    { "<leader>gf", "<cmd>CodeDiff file HEAD<cr>", desc = "Diff file vs HEAD" },
    {
      "<leader>gF",
      function()
        vim.ui.input({ prompt = "File diff against: " }, function(input)
          if input then
            vim.cmd("CodeDiff file " .. input)
          end
        end)
      end,
      desc = "Diff file vs revision",
    },
  },
}
