return {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "hrsh7th/cmp-buffer", -- source for text in buffer
    "hrsh7th/cmp-path", -- source for file system paths
    "hrsh7th/cmp-cmdline", -- commandline autocompletion
    {
      "L3MON4D3/LuaSnip",
      build = "make install_jsregexp",
    }, -- luasnip
    {
      "rafamadriz/friendly-snippets",
      config = function()
        require("luasnip.loaders.from_vscode").lazy_load()
      end,
    }, -- community made snippets
    "saadparwaiz1/cmp_luasnip", -- for autocompletion
    "onsails/lspkind.nvim", -- vs-code like pictograms
  },

  config = function()
    local cmp = require("cmp")

    local luasnip = require("luasnip")
    luasnip.setup({
      updateevents = "TextChangedI",
      enable_autosnippets = true,
    })

    vim.cmd([[
      imap <silent><expr> <Tab> luasnip#expand_or_jumpable() ? '<Plug>luasnip-expand-or-jump' : '<Tab>' 
      inoremap <silent> <S-Tab> <cmd>lua require'luasnip'.jump(-1)<Cr>
      snoremap <silent> <Tab> <cmd>lua require('luasnip').jump(1)<Cr>
      snoremap <silent> <S-Tab> <cmd>lua require('luasnip').jump(-1)<Cr>
    ]])

    local lspkind = require("lspkind")

    cmp.setup({
      completion = {
        completeopt = "menu,preview,noselect",
      },
      snippet = { -- configure how nvim-cmp interacts with snippet engine
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },

      mapping = cmp.mapping.preset.insert({
        ["<C-k>"] = cmp.mapping.confirm({ noremap = true, select = true }),
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
        ["<tab>"] = cmp.config.disable,
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
      }),
      -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline({}),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
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
}
