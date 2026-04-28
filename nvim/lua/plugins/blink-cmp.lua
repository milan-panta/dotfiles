return {
  "saghen/blink.cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "saghen/blink.lib",
    "rafamadriz/friendly-snippets",
  },

  build = function()
    -- build the fuzzy matcher, wait up to 60 seconds
    -- you can use `gb` in `:Lazy` to rebuild the plugin as needed
    require("blink.cmp").build():wait(60000)
  end,

  opts = {
    fuzzy = { implementation = "rust" },
    keymap = {
      preset = "super-tab",
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
      menu = { auto_show = true, max_height = 20 },
      list = { max_items = 50 },
      documentation = { auto_show = true, auto_show_delay_ms = 50 },
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
  },
  opts_extend = { "sources.default" },
}
