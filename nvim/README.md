# Nvim 0.13+ (nightly build)

## Layout

```
~/.config/nvim/
├── init.lua                  # loads config modules
├── lua/config/
│   ├── lazy.lua              # plugin manager bootstrap
│   ├── options.lua           # core vim options
│   ├── keymaps.lua           # global (non-plugin) keymaps
│   ├── autocmds.lua          # global autocommands
│   └── tools.lua             # tooling registry (LSP/formatters/linters/DAP/parsers)
└── lua/plugins/              # plugin specs (one file per feature)
```

## Tools live in one place

`lua/config/tools.lua` defines LSP servers, formatters, linters, DAP adapters, and treesitter parsers. Everything else reads from it (mason, lspconfig, conform, nvim-lint, mason-nvim-dap, treesitter).

Add a language:

1. `tools.servers` (LSP)
2. `tools.formatters_by_ft`
3. `tools.linters_by_ft`
4. `tools.dap_adapters` (if needed)
5. `tools.treesitter_parsers`

## Dependencies

- node, yarn
- tree-sitter, tree-sitter-cli
- python3, go
- fzf, fd, ripgrep
- tmux (optional, for run keymaps)

## macOS note

Enable “Option as Meta” so the Alt/Meta keymaps work.
