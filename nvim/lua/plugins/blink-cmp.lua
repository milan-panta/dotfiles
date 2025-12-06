return {
  "saghen/blink.cmp",
  version = "1.*",
  event = { "InsertEnter", "CmdlineEnter" },
  opts = {
    keymap = {
      preset = "default",
      ["<Tab>"] = {
        function(cmp)
          if vim.lsp.inline_completion and vim.lsp.inline_completion.get() then
            vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-l>", true, true, true), "m", true)
            return true
          end
        end,
        "select_next",
        "snippet_forward",
        "fallback",
      },
    },
    appearance = {
      nerd_font_variant = "mono",
    },
    signature = { enabled = true, window = { show_documentation = true } },
    cmdline = { completion = { menu = { auto_show = true } } },
    completion = {
      documentation = {
        auto_show = true,
        auto_show_delay_ms = 0,
      },
      ghost_text = { enabled = true },
    },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
    fuzzy = { implementation = "rust" },
  },
  opts_extend = { "sources.default" },
}
