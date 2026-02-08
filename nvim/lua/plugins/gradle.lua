return {
  "oclay1st/gradle.nvim",
  ft = { "java", "kotlin", "groovy" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
  cmd = { "Gradle", "GradleExec" },
  -- stylua: ignore
  keys = {
    { "<leader>Gx", "<cmd>Gradle<cr>", desc = "Execute Gradle Task" },
    { "<leader>Gb", "<cmd>GradleExec build<cr>", desc = "Gradle Build" },
    { "<leader>Gt", "<cmd>GradleExec test<cr>", desc = "Gradle Test" },
    { "<leader>Gr", "<cmd>GradleExec run<cr>", desc = "Gradle Run" },
    { "<leader>Gc", "<cmd>GradleExec clean<cr>", desc = "Gradle Clean" },
  },
  opts = {},
}
