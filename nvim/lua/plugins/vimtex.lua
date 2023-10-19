return {
  "lervag/vimtex",
  ft = "tex",
  config = function()
    vim.cmd([[
    let g:vimtex_format_enabled = 1
    let g:vimtex_quickfix_open_on_warning = 0
    let g:vimtex_quickfix_ignore_filters = [
    \ 'Underfull \\hbox',
    \ 'Overfull \\hbox',
    \ 'LaTeX Warning: .\+ float specifier changed to',
    \ 'LaTeX hooks Warning',
    \ 'Package siunitx Warning: Detected the "physics" package:',
    \ 'Package hyperref Warning: Token not allowed in a PDF string',
    \]
    " let g:vimtex_view_method = 'skim'
    let g:vimtex_view_method='zathura'
    ]])
  end,
}
