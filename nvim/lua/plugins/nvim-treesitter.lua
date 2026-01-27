-- Treesitter: syntax parsing/highlighting

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  lazy = vim.fn.argc(-1) == 0, -- Load early when opening a file from cmdline
  cmd = { "TSUpdate", "TSInstall", "TSInstallInfo" },
  config = function()
    local tools = require("config.tools")
    local ts = require("nvim-treesitter")
    ts.setup()

    -- Install configured parsers (async to not block startup)
    vim.schedule(function()
      ts.install(tools.treesitter_parsers)
    end)

    -- Enable treesitter features per-filetype
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter_features", { clear = true }),
      desc = "Enable Treesitter highlighting and indentation",
      callback = function()
        local filetype = vim.bo.filetype
        local lang = vim.treesitter.language.get_lang(filetype)
        if not lang then
          return
        end

        -- Enable highlighting if available
        if vim.treesitter.query.get(lang, "highlights") then
          vim.treesitter.start()
        end

        -- Enable treesitter-based indentation if available
        if vim.treesitter.query.get(lang, "indents") then
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
