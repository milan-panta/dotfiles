return {
  "esmuellert/codediff.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  commit = "5e69152",
  cmd = "CodeDiff",
  keys = {
    { "<leader>gd", "<cmd>CodeDiff<cr>", desc = "Changes Explorer" },
    {
      "<leader>gD",
      function()
        vim.ui.input({ prompt = "Revision: " }, function(input)
          if input then
            vim.cmd("CodeDiff " .. input)
          end
        end)
      end,
      desc = "Changes Explorer vs Revision",
    },
    { "<leader>gp", "<cmd>CodeDiff main...<cr>", desc = "PR Changes (vs main)" },
    { "<leader>gh", "<cmd>CodeDiff history<cr>", desc = "Repo History" },
    { "<leader>gH", "<cmd>CodeDiff history %<cr>", desc = "File History" },
    { "<leader>gc", "<cmd>CodeDiff history --base WORKING<cr>", desc = "Repo History (diff vs working)" },
    { "<leader>gC", "<cmd>CodeDiff history --base WORKING %<cr>", desc = "File History (diff vs working)" },
    { "<leader>gf", "<cmd>CodeDiff file HEAD<cr>", desc = "Diff File vs HEAD" },
    {
      "<leader>gF",
      function()
        vim.ui.input({ prompt = "Revision(s): " }, function(input)
          if input then
            vim.cmd("CodeDiff file " .. input)
          end
        end)
      end,
      desc = "Diff File vs Revision",
    },
  },
}
