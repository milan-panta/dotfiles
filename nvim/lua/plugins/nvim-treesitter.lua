return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  dependencies = {
    "windwp/nvim-ts-autotag",
  },
  config = function()
    -- import nvim-treesitter plugin
    local treesitter = require("nvim-treesitter.configs")

    -- configure treesitter
    treesitter.setup({ -- enable syntax highlighting
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
        disable = { "tex", "latex" },
      },
      modules = {},
      -- enable indentation
      indent = { enable = true },
      -- enable autotagging (w/ nvim-ts-autotag plugin)
      autotag = { enable = true },
      -- ignore installed
      ignore_install = {},
      -- ensure these language parsers are installed
      ensure_installed = {
        "python",
        "css",
        "markdown",
        "markdown_inline",
        "javascript",
        "json",
        "vim",
        "latex",
        "typescript",
        "vimdoc",
        "bash",
        "cpp",
        "rust",
        "regex",
        "toml",
        "lua",
        "c",
        "gitignore",
      },
      sync_install = false,
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<M-space>",
          node_incremental = "<M-space>",
          node_decremental = "<bs>",
        },
      },
      -- enable nvim-ts-context-commentstring plugin for commenting tsx and jsx
      context_commentstring = {
        enable = true,
        enable_autocmd = false,
      },
      -- auto install above language parsers
      auto_install = true,
    })
  end,
}
