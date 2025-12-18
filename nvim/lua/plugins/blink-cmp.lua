return {
  "saghen/blink.cmp",
  dependencies = { "rafamadriz/friendly-snippets" },
  build = "cargo build --release",
  event = { "InsertEnter", "CmdlineEnter" },

  opts = {
    appearance = {
      nerd_font_variant = "mono",
    },

    cmdline = {
      keymap = { preset = "inherit" },
      completion = { menu = { auto_show = true } },
    },

    completion = {
      menu = { auto_show = true, auto_show_delay_ms = 0 },
      documentation = { auto_show = true, auto_show_delay_ms = 0 },
    },

    signature = { enabled = true },

    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },

    fuzzy = { implementation = "rust" },
  },
  opts_extend = { "sources.default" },
}
