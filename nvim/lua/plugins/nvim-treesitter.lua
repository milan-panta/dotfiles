return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  event = { "BufReadPost", "BufNewFile", "BufWritePre", "VeryLazy" },
  cmd = { "TSUpdate", "TSInstall", "TSLog", "TSUninstall" },
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter").setup({
      ensure_installed = {
        "bash",
        "c",
        "cpp",
        "css",
        "gitignore",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "ron",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      desc = "Enable Treesitter features",
      callback = function()
        local filetype = vim.bo.filetype
        local lang = vim.treesitter.language.get_lang(filetype)
        if not lang then
          return
        end

        if vim.treesitter.query.get(lang, "highlights") then
          vim.treesitter.start()
        end
        if vim.treesitter.query.get(lang, "indents") then
          vim.bo.indentexpr = "v:lua.require('nvim-treesitter').indentexpr()"
        end
      end,
    })
  end,
}
