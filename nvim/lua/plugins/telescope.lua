return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
    {
      "debugloop/telescope-undo.nvim",
      event = { "BufReadPre", "BufNewFile" },
    },
  },
  config = function()
    local telescope = require("telescope")
    telescope.load_extension("fzf")
    telescope.load_extension("undo")
    local actions = require("telescope.actions")
    telescope.setup({
      defaults = {
        mappings = {
          i = {
            ["<Esc>"] = actions.close,
          },
        },
        layout_strategy = "horizontal",
        layout_config = {
          horizontal = {
            prompt_position = "top",
            preview_width = 0.5,
          },
          width = 0.8,
          height = 0.8,
          preview_cutoff = 120,
        },
        sorting_strategy = "ascending",
        winblend = 0,
      },
    })
  end,
  cmd = {
    "Telescope",
  },
  keys = {
    {
      "<Leader>ff",
      function()
        require("telescope.builtin").fd({ hidden = true })
      end,
      desc = "Telescope find files",
    },
    {
      "<Leader>fF",
      function()
        require("telescope.builtin").git_files()
      end,
      desc = "Telescope find Git files",
    },
    {
      "<Leader>fg",
      function()
        require("telescope.builtin").live_grep()
      end,
      desc = "Telescope live grep",
    },
    {
      "<Leader>fh",
      function()
        require("telescope.builtin").help_tags()
      end,
      desc = "Telescope find help tags",
    },
    {
      "<Leader>fd",
      function()
        require("telescope.builtin").diagnostics()
      end,
      desc = "Telescope diagnostics",
    },
    {
      "<Leader>fr",
      function()
        require("telescope.builtin").oldfiles()
      end,
      desc = "Telescope find recent files",
    },
    {
      "<Leader>fk",
      function()
        require("telescope.builtin").keymaps()
      end,
      desc = "Telescope find keymaps",
    },
    {
      "<Leader>/",
      function()
        require("telescope.builtin").current_buffer_fuzzy_find()
      end,
      desc = "Telescope fuzzy search current buffer",
    },
    {
      "<Leader>fq",
      function()
        require("telescope.builtin").quickfix()
      end,
      desc = "Telescope quickfix",
    },
    {
      "<Leader>U",
      function()
        require("telescope").extensions.undo.undo()
      end,
      desc = "Telescope Undo",
    },
    {
      "<Leader>fb",
      function()
        require("telescope").buffers()
      end,
      desc = "Telescope Undo",
    },
  },
}
