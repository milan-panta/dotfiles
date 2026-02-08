return {
  "saghen/blink.cmp",
  version = "1.*",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "rafamadriz/friendly-snippets",
  },

  opts = {
    keymap = {
      preset = "default",
      ["<C-space>"] = { "select_and_accept", "fallback" },
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
      ghost_text = { enabled = false },
      accept = { auto_brackets = { enabled = true } },
    },

    signature = {
      enabled = true,
      window = { show_documentation = true, scrollbar = true },
    },

    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
      providers = {
        lsp = {
          transform_items = function(_, items)
            -- Filter out Text (1) and Reference (18) from markdown files (likely marksman headers)
            if vim.bo.filetype == "markdown" then
              local kind = require("blink.cmp.types").CompletionItemKind
              return vim.tbl_filter(function(item)
                return item.kind ~= kind.Text and item.kind ~= kind.Reference
              end, items)
            end
            return items
          end,
        },
      },
    },

    fuzzy = { implementation = "rust" },
  },
  opts_extend = { "sources.default" },
}
