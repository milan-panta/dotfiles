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
    {
      "<leader>gg",
      function()
        local file = vim.fn.expand("%")
        if file == "" then
          vim.notify("No file in current buffer", vim.log.levels.WARN)
          return
        end
        local result = vim.fn.systemlist({ "git", "log", "--pretty=format:%h %s", "-20", "--", file })
        if vim.v.shell_error ~= 0 or #result == 0 then
          vim.notify("No git history for this file", vim.log.levels.WARN)
          return
        end
        vim.ui.select(result, { prompt = "Diff current file vs commit:" }, function(choice)
          if choice then
            local sha = choice:match("^(%S+)")
            vim.cmd("CodeDiff file " .. sha)
          end
        end)
      end,
      desc = "Diff file vs picked commit",
    },
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
