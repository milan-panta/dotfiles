return {
  "lervag/vimtex",
  ft = "tex",
  config = function()
    vim.g.vimtex_format_enabled = 1
    vim.g.vimtex_quickfix_open_on_warning = 0
    vim.g.vimtex_quickfix_ignore_filters = {
      "Underfull \\hbox",
      "Overfull \\hbox",
      "LaTeX Warning: .+ float specifier changed to",
      "LaTeX hooks Warning",
      'Package siunitx Warning: Detected the "physics" package:',
      "Package hyperref Warning: Token not allowed in a PDF string",
    }
    vim.g.vimtex_view_method = "zathura"
  end,
}
