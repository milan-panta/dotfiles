return {
  "saghen/blink.cmp",
  version = "1.*",
  dependencies = { "rafamadriz/friendly-snippets" },
  event = { "InsertEnter", "CmdlineEnter" },

  opts = {
    keymap = {
      preset = "default",
      ["<C-b>"] = { "scroll_documentation_up", "scroll_signature_up", "fallback" },
      ["<C-f>"] = { "scroll_documentation_down", "scroll_signature_down", "fallback" },
    },

    appearance = {
      nerd_font_variant = "mono",
    },

    cmdline = {
      keymap = { preset = "inherit" },
      completion = { menu = { auto_show = true } },
    },

    completion = {
      menu = { auto_show = true },
      documentation = { auto_show = true, auto_show_delay_ms = 100 },
    },

    signature = {
      enabled = true,
      window = { show_documentation = true, scrollbar = true },
    },

    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },

    fuzzy = { implementation = "rust" },
  },
  opts_extend = { "sources.default" },
}
