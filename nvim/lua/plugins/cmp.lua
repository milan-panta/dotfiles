return {
  {
    "L3MON4D3/LuaSnip",
    dependencies = {
      "rafamadriz/friendly-snippets",
    },
    build = "make install_jsregexp",
    config = function()
      require("luasnip.loaders.from_vscode").lazy_load({ paths = "~/.config/nvim/snippets/vscode" })

      local luasnip = require("luasnip")
      luasnip.setup({
        updateevents = "TextChangedI",
        enable_autosnippets = true,
      })
    end,
    keys = {
      {
        "<tab>",
        function()
          return require("luasnip").jumpable(1) and "<Plug>luasnip-jump-next" or "<tab>"
        end,
        expr = true,
        silent = true,
        mode = "i",
      },
      {
        "<tab>",
        function()
          require("luasnip").jump(1)
        end,
        mode = "s",
      },
      {
        "<s-tab>",
        function()
          require("luasnip").jump(-1)
        end,
        mode = { "i", "s" },
      },
      {
        "<Leader><Leader>s",
        '<Cmd>w<CR><Cmd>lua require("luasnip.loaders.from_lua").load({paths = "~/.config/nvim/snippets/"})<CR>',
        desc = "Load snippets",
      },
    },
  },
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-buffer", -- source for text in buffer
      "hrsh7th/cmp-path", -- source for file system paths
      "hrsh7th/cmp-cmdline", -- commandline autocompletion
      "saadparwaiz1/cmp_luasnip", -- for autocompletion
      "onsails/lspkind.nvim", -- vs-code like pictograms
    },

    config = function()
      local cmp = require("cmp")

      local lspkind = require("lspkind")
      local winhighlight = "Normal:Normal,FloatBorder:Normal,CursorLine:Visual,Search:None"

      cmp.setup({
        completion = {
          completeopt = "menu,preview,noselect",
        },
        window = {
          completion = {
            winhighlight = winhighlight,
            border = "rounded",
            scrollbar = false,
          },
          documentation = {
            winhighlight = winhighlight,
            border = "rounded",
          },
        },
        snippet = { -- configure how nvim-cmp interacts with snippet engine
          expand = function(args)
            require("luasnip").lsp_expand(args.body)
          end,
        },

        mapping = cmp.mapping.preset.insert({
          ["<C-k>"] = cmp.mapping.confirm({ noremap = true, select = true }),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<C-u>"] = cmp.mapping.scroll_docs(-4),
          ["<C-d>"] = cmp.mapping.scroll_docs(4),
          ["<Tab>"] = nil,
          ["<S-Tab>"] = nil,
        }),

        -- sources for autocompletion
        sources = cmp.config.sources({
          { name = "luasnip" }, -- snippets
          { name = "nvim_lsp" },
          { name = "buffer" }, -- text within current buffer
          { name = "path" }, -- file system paths
        }),
        -- Use buffer source for `/` and `?` (if you enabled `native_menu`, this won't work anymore).

        cmp.setup.cmdline({ "/", "?" }, {
          mapping = cmp.mapping.preset.cmdline({}),
          sources = {
            { name = "buffer" },
          },
          window = {
            completion = {
              border = "none",
            },
          },
        }),

        -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
        cmp.setup.cmdline(":", {
          mapping = cmp.mapping.preset.cmdline({}),
          sources = cmp.config.sources({
            { name = "path" },
          }, {
            { name = "cmdline" },
          }),
          window = {
            completion = {
              border = "none",
            },
          },
        }),

        -- configure lspkind for vs-code like pictograms in completion menu
        formatting = {
          format = lspkind.cmp_format({
            maxwidth = 50,
            ellipsis_char = "...",
          }),
        },
      })
    end,
  },
}
