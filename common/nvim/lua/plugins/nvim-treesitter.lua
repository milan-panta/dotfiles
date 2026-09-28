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
      local installed = {}
      for _, lang in ipairs(ts.get_installed("parsers")) do
        installed[lang] = true
      end

      local missing = vim.tbl_filter(function(lang)
        return not installed[lang]
      end, tools.treesitter_parsers)
      if #missing > 0 then
        ts.install(missing)
      end
    end)

    -- Compiling a highlight query blocks the UI (~500ms for Haskell, ~300ms
    -- for C++, because their grammars are huge). Neovim caches compiled
    -- queries per session, so only the first buffer of each language pays.
    -- Defer that first compile so the file is drawn (with regex syntax)
    -- before the stall, instead of delaying startup.
    local compiled = {}
    local function start_highlighting(buf, lang)
      local function start()
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        local ok, hl_query = pcall(vim.treesitter.query.get, lang, "highlights")
        compiled[lang] = true
        if ok and hl_query then
          vim.treesitter.start(buf, lang)
        end
      end
      if compiled[lang] then
        start()
      else
        vim.defer_fn(start, 20)
      end
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter_features", { clear = true }),
      callback = function(event)
        local filetype = vim.bo[event.buf].filetype
        local lang = vim.treesitter.language.get_lang(filetype)
        if not lang then
          return
        end

        start_highlighting(event.buf, lang)

        -- Compile indentation queries only when indentation is requested.
        if #vim.treesitter.query.get_files(lang, "indents") > 0 then
          vim.bo[event.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
