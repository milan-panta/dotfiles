return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  cmd = "FzfLua",
  keys = {
    {
      "<Leader><Leader>",
      function()
        require("fzf-lua").files()
      end,
      desc = "FzfLua find files",
    },
    {
      "<Leader>fg",
      function()
        require("fzf-lua").live_grep()
      end,
      desc = "FzfLua live grep",
    },
    {
      "<Leader>fh",
      function()
        require("fzf-lua").helptags()
      end,
      desc = "FzfLua help tags",
    },
    {
      "<Leader>fd",
      function()
        require("fzf-lua").diagnostics_document()
      end,
      desc = "FzfLua diagnostics (document)",
    },
    {
      "<Leader>fl",
      function()
        require("fzf-lua").lsp_document_symbols()
      end,
      desc = "FzfLua document symbols",
    },
    {
      "<Leader>fr",
      function()
        require("fzf-lua").oldfiles()
      end,
      desc = "FzfLua recent files",
    },
    {
      "<Leader>fk",
      function()
        require("fzf-lua").keymaps()
      end,
      desc = "FzfLua keymaps",
    },
    {
      "<Leader>/",
      function()
        require("fzf-lua").blines()
      end,
      desc = "FzfLua fuzzy search current buffer",
    },
    {
      "<Leader>fq",
      function()
        require("fzf-lua").quickfix()
      end,
      desc = "FzfLua quickfix",
    },
    {
      "<Leader>U",
      function()
        require("fzf-lua").changes()
      end,
      desc = "FzfLua Changes",
    },
    {
      "<Leader>fb",
      function()
        require("fzf-lua").buffers()
      end,
      desc = "FzfLua buffers",
    },
    {
      "<Leader>fc",
      function()
        require("fzf-lua").files({
          cwd = vim.fn.expand("~/.config/nvim/lua"),
          prompt = "Config> ",
          cmd = "rg --files --hidden -g !.git -g !venv -g !_build",
        })
      end,
      desc = "FzfLua Config",
    },
  },
  config = function(_, opts)
    require("fzf-lua").setup(opts)
    require("fzf-lua").register_ui_select()
  end,
}
