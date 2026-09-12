return {
  "lervag/vimtex",
  -- VimTeX handles filetype loading itself and needs to be available at startup.
  lazy = false,
  init = function()
    vim.g.vimtex_view_method = "sioyek"
    vim.g.vimtex_quickfix_open_on_warning = 0
    vim.g.vimtex_quickfix_ignore_filters = {
      "Underfull \\hbox",
      "Overfull \\hbox",
      "LaTeX Warning: .+ float specifier changed to",
      "LaTeX hooks Warning",
      'Package siunitx Warning: Detected the "physics" package:',
      "Package hyperref Warning: Token not allowed in a PDF string",
    }
    if vim.fn.executable("latexmk") == 1 then
      vim.g.vimtex_compiler_method = "latexmk"
      vim.g.vimtex_compiler_latexmk = {
        options = {
          "-verbose",
          "-file-line-error",
          "-synctex=1",
          "-interaction=nonstopmode",
          "--shell-escape",
        },
      }
    elseif vim.fn.executable("tectonic") == 1 then
      vim.g.vimtex_compiler_method = "tectonic"
    else
      vim.notify("VimTeX: install latexmk or tectonic to enable compilation", vim.log.levels.WARN)
    end
  end,
  config = function()
    local pending = {}
    local function compile_when_ready(root)
      local buf = pending[root]
      if not buf or not vim.api.nvim_buf_is_loaded(buf) then
        pending[root] = nil
        return
      end
      vim.api.nvim_buf_call(buf, function()
        local state = vim.b.vimtex
        if not state or not state.compiler or not state.compiler.enabled then
          pending[root] = nil
          return
        end
        -- Queue the latest save while Tectonic is busy; never stop a running build.
        if vim.fn.eval("b:vimtex.compiler.is_running()") == 1 then
          vim.defer_fn(function()
            compile_when_ready(root)
          end, 200)
          return
        end
        pending[root] = nil
        vim.cmd("VimtexCompileSS")
      end)
    end

    vim.api.nvim_create_autocmd("BufWritePost", {
      group = vim.api.nvim_create_augroup("vimtex_compile_on_save", { clear = true }),
      pattern = "*.tex",
      callback = function(event)
        local state = vim.b[event.buf].vimtex
        if not state or not state.compiler or state.compiler.name ~= "tectonic" then
          return
        end
        local root = state.tex
        local queued = pending[root] ~= nil
        pending[root] = event.buf
        if not queued then
          vim.defer_fn(function()
            compile_when_ready(root)
          end, 200)
        end
      end,
    })
  end,
}
