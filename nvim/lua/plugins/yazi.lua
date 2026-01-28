return {
  "mikavilpas/yazi.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true },
  },
  keys = {
    { "<leader>ll", mode = { "n", "v" }, "<cmd>Yazi<cr>", desc = "Open yazi at the current file" },
    { "<leader>lL", "<cmd>Yazi cwd<cr>", desc = "Open the file manager in nvim's working directory" },
    { "<leader>ly", "<cmd>Yazi toggle<cr>", desc = "Resume last yazi session" },
  },
  ---@type YaziConfig
  opts = {
    open_for_directories = true,
    integrations = {
      grep_in_directory = function(directory)
        Snacks.picker.grep({ cwd = directory })
      end,
      grep_in_selected_files = function(selected_files)
        Snacks.picker.grep({ dirs = selected_files })
      end,
    },
  },
  init = function()
    -- Disable netrw so yazi opens for directories
    vim.g.loaded_netrwPlugin = 1
  end,
}
