return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "helix",
    spec = {
      { "<leader>a", group = "ai/sidekick" },
      { "<leader>c", group = "code" },
      { "<leader>C", group = "CMake/C++" },
      { "<leader>d", group = "debug" },
      { "<leader>f", group = "find" },
      { "<leader>g", group = "git" },
      { "<leader>G", group = "Gradle" },
      { "<leader>h", group = "hunk" },
      { "<leader>o", group = "obsidian" },
      { "<leader>q", group = "session" },
      { "<leader>r", group = "run/refactor" },
      { "<leader>s", group = "search" },
      { "<leader>t", group = "test" },
      { "<leader>u", group = "ui" },
      {
        "<leader>w",
        group = "windows",
        proxy = "<c-w>",
        expand = function()
          return require("which-key.extras").expand.win()
        end,
      },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Keymaps (which-key)",
    },
    {
      "<c-w><space>",
      function()
        require("which-key").show({ keys = "<c-w>", loop = true })
      end,
      desc = "Window Hydra Mode (which-key)",
    },
  },
}
