return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "debugloop/telescope-undo.nvim",
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    telescope.setup({
      defaults = {
        file_ignore_patterns = { "node_modules" },
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
          width = 0.9,
          height = 0.9,
          preview_cutoff = 120,
        },
        sorting_strategy = "ascending",
        path_display = { "truncate" },
        dynamic_preview_title = true,
        winblend = 0,
      },
    })
    require("telescope").load_extension("fzf")
    require("telescope").load_extension("undo")
  end,
  cmd = {
    "Telescope",
  },
  keys = {
    {
      "<Leader><Leader>",
      function()
        require("telescope.builtin").fd({ hidden = true })
      end,
      desc = "Telescope find files",
    },
    {
      "<Leader>fF",
      function()
        vim.cmd("Telescope find_files cwd=" .. vim.fn.expand("%:h"))
      end,
      desc = "Telescope find files in cwd",
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
      "<Leader>fl",
      function()
        require("telescope.builtin").lsp_document_symbols()
      end,
      desc = "Telescope document symbols",
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
        vim.cmd("Telescope undo")
      end,
      desc = "Telescope Undo",
    },
    {
      "<Leader>fb",
      function()
        require("telescope.builtin").buffers()
      end,
      desc = "Telescope buffers",
    },
    {
      "<Leader>fc",
      function()
        vim.cmd([[Telescope fd cwd=~/.config/nvim/lua/ prompt_title=Config]])
      end,
      desc = "Telescope Config",
    },
  },
}
