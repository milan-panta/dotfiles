return {
  "mikavilpas/yazi.nvim",
  keys = {
    { "<leader>-", mode = { "n", "v" }, "<cmd>Yazi<cr>", desc = "Open yazi at the current file" },
    { "<leader>_", "<cmd>Yazi cwd<cr>", desc = "Open the file manager in nvim's working directory" },
    { "<leader>cw", "<cmd>Yazi toggle<cr>", desc = "Resume last yazi session" },
  },
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
  ---@type YaziConfig
  opts = {
    open_for_directories = false,
    integrations = {
      grep_in_directory = function(directory)
        Snacks.picker.grep({ cwd = directory })
      end,
      grep_in_selected_files = function(selected_files)
        Snacks.picker.grep({ dirs = selected_files })
      end,
    },
  },
}
