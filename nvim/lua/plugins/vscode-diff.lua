return {
  "esmuellert/vscode-diff.nvim",
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
    { "<leader>hd", "<cmd>CodeDiff file HEAD<cr>", desc = "Diff file" },
    {
      "<leader>hD",
      function()
        vim.ui.input({ prompt = "File diff against: " }, function(input)
          if input then
            vim.cmd("CodeDiff file " .. input)
          end
        end)
      end,
      desc = "Diff file against revision",
    },
  },
}
