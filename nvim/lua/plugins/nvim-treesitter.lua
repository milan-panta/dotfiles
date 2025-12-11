return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  build = ":TSUpdate",
  config = function()
    -- import nvim-treesitter plugin
    local treesitter = require("nvim-treesitter.configs")

    -- configure treesitter
    treesitter.setup({ -- enable syntax highlighting
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      modules = {},
      -- enable indentation
      indent = { enable = false },
      -- ignore installed
      ignore_install = {},
      -- ensure these language parsers are installed
      ensure_installed = {
        "bash",
        "c",
        "cpp",
        "css",
        "gitignore",
        "javascript",
        "json",
        "latex",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
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
      -- auto install above language parsers
      auto_install = false,
    })
  end,
}
