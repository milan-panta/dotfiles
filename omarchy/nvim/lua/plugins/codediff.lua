local function git()
  return require("config.git")
end

return {
  "esmuellert/codediff.nvim",
  dependencies = { "MunifTanjim/nui.nvim" },
  cmd = "CodeDiff",
  -- stylua: ignore
  keys = {
    { "<leader>gd", "<cmd>CodeDiff<cr>", desc = "Diff My Changes" },
    { "<leader>gD", function() git().diff_against() end, desc = "Diff Against Branch…" },
    { "<leader>gp", function() git().branch_changes() end, desc = "Diff This Branch (what a PR would contain)" },
    { "<leader>gi", function() git().incoming() end, desc = "Incoming Commits (fetch first)" },
    { "<leader>gh", "<cmd>CodeDiff history %<cr>", desc = "History of This File" },
    { "<leader>gH", "<cmd>CodeDiff history<cr>", desc = "History of the Repo" },
    { "<leader>gm", function() git().conflicts() end, desc = "Resolve Merge Conflicts" },
  },
  opts = {
    keymaps = {
      view = {
        -- <leader>b is a prefix of the build keys and would wait; gc is the comment operator.
        toggle_explorer = "<leader>e",
        focus_explorer = false,
        toggle_compact = "gz",
      },
    },
  },
}
