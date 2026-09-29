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

1. `tools.servers` (Mason-managed LSP) or `tools.system_servers` (existing installations)
2. `tools.formatters_by_ft`
3. `tools.linters_by_ft`
4. `tools.mason_dap_adapters` (if needed; GDB is installed system-wide)
5. `tools.treesitter_parsers`

## Dependencies

- node, yarn
- tree-sitter, tree-sitter-cli
- python3, go
- gcc, g++, gdb 14+
- fzf, fd, ripgrep
- tmux (optional, for run keymaps)
- cmake, meson, make, ninja (optional, for project builds)
- latexmk or tectonic (optional, for VimTeX compilation and rendered math)

This configuration targets Linux and integrates with Omarchy when available.
The macOS counterpart lives in `mac/nvim`.

## Haskell

HLS runs through `~/.ghcup/bin/haskell-language-server-wrapper`, with
`~/.ghcup/bin` first in its PATH so it uses the GHC version selected in GHCup.
HLS and GHC are not installed or updated by Mason. Keep the course-required
versions selected in GHCup.

Open a `.hs` or `.lhs` file for completion, hover (`K`), rename (`cd`), and code
actions (`g.`). Formatting on save and `<leader>cf` use HLS's formatter.
Diagnostics follow the existing global toggle (`<leader>ud`).

For `.hs` and `.lhs` files, `<leader>rr`, `<leader>ra`, and `<leader>ro` all open
the current file in `~/.ghcup/bin/ghci`, without prompting for arguments.
Use the GHCi prompt to evaluate expressions, `:reload` to reload changes, and
`:quit` to exit. The session uses the existing tmux runner window or a Neovim
terminal split.

## C/C++ build and debug

- `<leader>bp` detects and builds CMake, Meson, Make, or Ninja projects.
- `<leader>dd` builds the current project (or standalone source) and starts GDB.
- DAP launch choices also support quoted arguments, core dumps, and gdbserver.
