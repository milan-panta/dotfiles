return {
  "saghen/blink.cmp",
  version = "1.*",
  event = { "InsertEnter", "CmdlineEnter" },
  opts = {
    keymap = { preset = "default" },
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
