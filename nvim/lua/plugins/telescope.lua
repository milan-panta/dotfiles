-- lua/plugins/telescope.lua
return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "debugloop/telescope-undo.nvim",
  },
  cmd = { "Telescope" },
  keys = {
    {
      "<Leader><Leader>",
      function()
        require("telescope.builtin").find_files({ hidden = true })
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
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local undo_actions = require("telescope-undo.actions")

    telescope.setup({
      defaults = {
        initial_mode = "insert",
        mappings = {
          i = {
            ["<ESC>"] = actions.close,
          },
        },
        layout_strategy = "flex",
        layout_config = {
          width = 0.96,
          height = 0.94,
          prompt_position = "top",
          preview_cutoff = 110, -- switch to vertical below this width
          horizontal = {
            preview_width = 0.58, -- results get the remainder
          },
          vertical = {
            preview_height = 0.52,
          },
        },
        sorting_strategy = "ascending",
        history = { cycle_wrap = true },
        prompt_prefix = " \239\128\130  ",
        selection_caret = "  ",
        entry_prefix = "  ",
      },

      pickers = {
        buffers = { theme = "ivy", previewer = false },
        oldfiles = { theme = "ivy", previewer = false },
        find_files = {
          theme = "ivy",
          hidden = true,
          find_command = {
            "rg",
            "--files",
            "--glob",
            "!.git",
            "--glob",
            "!venv",
            "--glob",
            "!_build",
            "--hidden",
          },
          previewer = false,
        },
      },

      extensions = {
        fzf = {},
        undo = {
          use_delta = true,
          side_by_side = true,
          layout_strategy = "flex",
          layout_config = {
            width = 0.96,
            height = 0.94,
            prompt_position = "top",
            preview_cutoff = 110,
            horizontal = {
              preview_width = 0.62, -- give diff preview a bit more space
            },
            vertical = {
              preview_height = 0.55,
            },
          },
          mappings = {
            i = {
              ["<CR>"] = undo_actions.restore,
              ["<C-a>"] = undo_actions.yank_additions,
              ["<C-d>"] = undo_actions.yank_deletions,
              ["<C-y>"] = undo_actions.yank_state,
            },
            n = {
              ["<CR>"] = undo_actions.restore,
              ["a"] = undo_actions.yank_additions,
              ["d"] = undo_actions.yank_deletions,
              ["y"] = undo_actions.yank_state,
            },
          },
        },
      },
    })

    pcall(telescope.load_extension, "fzf")
    telescope.load_extension("undo")
  end,
}
