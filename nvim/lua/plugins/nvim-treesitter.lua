return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  event = { "BufReadPre", "BufNewFile" },
  lazy = vim.fn.argc(-1) == 0, -- Load early when opening a file from cmdline
  cmd = { "TSUpdate", "TSInstall", "TSInstallInfo" },
  config = function()
    local tools = require("config.tools")
    local ts = require("nvim-treesitter")
    ts.setup()

    vim.schedule(function()
      ts.install(tools.treesitter_parsers)
    end)

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter_features", { clear = true }),
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
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
