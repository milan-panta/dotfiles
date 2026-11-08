# Neovim config (Omarchy, Neovim 0.13 nightly)

A Neovim setup for Python, C/C++, Go, Rust, Haskell, Lua, TypeScript and LaTeX, with
one-key debugging, a gutter you can click for tests and breakpoints, and git
workflows built on CodeDiff, lazygit and the GitHub CLI. It needs Neovim 0.13
nightly or newer; older versions are not supported.

## Install

1. Link it: `./sync.sh` from the dotfiles root (it links `omarchy/nvim` to `~/.config/nvim`).
2. Start `nvim`. The first start installs the plugins, treesitter parsers and Mason
   tools (language servers, formatters, debug adapters). This takes 2 to 5 minutes and
   needs internet. Wait until the Mason pop-ups stop.
3. Restart `nvim`, then run `:checkhealth` to see what is missing on this machine.

## Requirements

| Needed for | Install |
|---|---|
| Everything | Neovim 0.13+, git, curl, unzip, a C compiler, `tree-sitter` CLI, ripgrep, fd |
| Language tools Mason can't install | node (TypeScript, Copilot), python3, go, rustup, GHCup (Haskell) |
| Debugging C/C++ | gdb 14+ |
| Git keys | lazygit, `gh` (logged in with `gh auth login`, for pull requests) |
| Running code and Haskell debugging | tmux (programs run in a pane on the right) |
| Project builds | cmake, meson, make or ninja |
| LaTeX | latexmk or tectonic; biber for bibliography completion |

This configuration targets Linux and integrates with Omarchy when available (theme,
clipboard). The macOS counterpart lives in `mac/nvim`.

## Keys to learn first

`<leader>` is Space. Press it and wait: which-key lists every key, grouped by letter.
`<leader>?` lists the keys for the current buffer.

| Key | Does |
|---|---|
| `<leader><leader>` / `<leader>sg` | Find files / grep the project |
| `<leader>e` / `<leader>-` | File tree / edit the folder as text (Oil) |
| `gd` `gr` `K` | Definition, references, hover |
| `cd` / `g.` / `<leader>cf` | Rename / code action / format |
| `<leader>tr` / `<leader>tf` | Run the test under the cursor / the file's tests |
| `F5` / `F9` | Debug this file or test / toggle a breakpoint |
| `<leader>gg` / `<leader>gd` | lazygit / diff your changes |
| `<leader>rr` | Run this file in the tmux pane on the right |

The groups: `a` AI, `b` build, `c` code, `d` debug, `f` find, `g` git, `h` hunk,
`j` competitive programming, `o` notes, `q` session, `r` run, `s` search, `t` test,
`u` toggles, `w` windows.

## Layout

```
~/.config/nvim/
├── init.lua                  # loads the modules below, in order
├── lua/config/
│   ├── lazy.lua              # plugin manager bootstrap
│   ├── options.lua           # editor options
│   ├── keymaps.lua           # keys that don't belong to a plugin; running files
│   ├── autocmds.lua          # autocommands
│   ├── tools.lua             # every LSP server, formatter, linter, debug adapter and parser
│   ├── debug.lua             # "debug this" per language, debug session helpers
│   ├── breakpoints.lua       # saved breakpoints, disable/enable, gutter clicks
│   ├── build.lua             # C/C++ project and single-file builds
│   ├── git.lua               # the git workflows behind <leader>g
│   ├── neotest_run.lua       # starting tests from a key (waits for discovery)
│   ├── neotest_python.lua    # doctest discovery for neotest-python
│   ├── omarchy_theme.lua     # follows the Omarchy theme
│   └── remote_clipboard.lua  # clipboard over OSC 52 (SSH, tmux)
├── lua/plugins/              # one file per feature; its keys are in its spec
├── snippets/, templates/     # snippets and competitive-programming templates
└── scripts/                  # square.sh, the dashboard's color square
```

To find a key: `<leader>sk` searches all of them. `:verbose nmap <key>` shows the file that defines it.

## Tools live in one place

`lua/config/tools.lua` defines LSP servers, formatters, linters, DAP adapters, and treesitter parsers. Everything else reads from it (mason, lspconfig, conform, nvim-lint, mason-nvim-dap, treesitter).

Add a language:

1. `tools.servers` (Mason-managed LSP) or `tools.system_servers` (existing installations)
2. `tools.formatters_by_ft`
3. `tools.linters_by_ft`
4. `tools.mason_dap_adapters` (if needed; GDB is installed system-wide)
5. `tools.treesitter_parsers`

## Git

Everything is under `<leader>g`, one meaning per letter. Diffs open in CodeDiff (`q` closes,
`]c`/`[c` hunks, `]f`/`[f` files, `-` stages a file, `<leader>hs`/`hu`/`hr` stage/unstage/discard a
hunk, `<leader>e` toggles its file list, `g?` shows its keys).

| Key | Does |
|---|---|
| `<leader>gg` | lazygit: commit, push, branches, rebase (`e` opens a file here) |
| `<leader>gs` | Changed files |
| `<leader>gd` | Diff my changes, staged and not |
| `<leader>gD` | Diff against a branch you pick |
| `<leader>gp` | This branch against the default branch: what a PR would contain |
| `<leader>gi` | Incoming: fetch, then the upstream commits you don't have, with diffs |
| `<leader>gh` / `gH` | History of this file / of the repo |
| `<leader>gb` / `gB` | Blame this line / the whole file |
| `<leader>go` | Open on GitHub (the line, or the selection) |
| `<leader>gP` | Pull requests: Enter for view, comment, review, checkout, merge; `<C-d>` to review side by side in CodeDiff |
| `<leader>gw` | Worktrees: switch, or start an offshoot (new branch, own folder, own tmux window) |
| `<leader>gm` | Resolve merge conflicts in this file |
| `<leader>gS` | Stashes |
| `]h` `[h`, `<leader>h…`, `ih` | Hunks in a normal buffer: move, stage (`hs`), unstage (`hu`), reset (`hr`), preview (`hp`), select |

An offshoot for an agent: `<leader>gw`, "New worktree…", a branch name. A tmux window opens
in `../<repo>-<branch>`; run the agent there. Review its work from your main checkout with
`<leader>gD` (pick its branch), and merge it with lazygit.

`git mergetool` and `git difftool` open CodeDiff and return to git when you press `q`.

## Debugging

One key starts the right thing per language: `<leader>dd` or `F5`.

- Python: the test at the cursor (or the test file), otherwise the file, in the project's `.venv`.
- C/C++: builds the project (or the file), picks the program once per project, then gdb.
  stdin comes from `<file>_input0.txt` (CompetiTest's samples) or, if the program reads
  stdin and there's no sample, from a tmux pane on the right. `<leader>dI` picks the input.
- Go: the test at the cursor, otherwise the package. Rust: rust-analyzer's target at the cursor.
- Haskell: `main` under hdb, the program in a tmux pane.

| Key | Does |
|---|---|
| `F5` / `<leader>dd` | Start, or continue when stopped |
| `F9` / `<leader>db` / click a line number | Toggle breakpoint (right-click the number for the menu) |
| `<leader>dB` `dH` `dL` | Condition, hit count, log message (no stop) |
| `<leader>dX` | Disable or enable the breakpoint on this line |
| `F10` `F11` `S-F11` / `<leader>dn` `di` `do` | Step over, into, out |
| `<leader>dC` / `<leader>dS` | Run to cursor / step into a chosen call |
| `<leader>dk` `dj` | Up / down the stack |
| `K` (while stopped) / `<leader>de` / `<leader>dw` | Value under cursor / evaluate selection / watch |
| `<leader>ds` `dr` `da` `dO` | Variables, REPL, all breakpoints, program console |
| `<leader>dx` / `<leader>dJ` | Which exceptions stop / just-my-code toggle |
| `<leader>dl` `dR` `dt` / `S-F5` | Rerun last, restart, stop (closes the view when idle) |
| `<leader>dD` | Pick a config: launch.json, with args, attach |
| `<leader>du` / `q` | Toggle / close the debug view |

Breakpoints are saved in `stdpath("state")/dap-breakpoints.json` and come back when a file opens.

## Tests in your projects

Tests show a ▶ in the gutter. Click it to run the test; right-click to debug it.

| Key | Does |
|---|---|
| `<leader>tr` / `<leader>td` | Run / debug the nearest test |
| `<leader>tf` / `<leader>tF` | Run this file / every test file |
| `<leader>tl` | Run the last test again |
| `<leader>ts` / `<leader>to` / `<leader>tO` | Summary / output of this test / output panel |
| `<leader>tw` / `<leader>tS` | Watch the file / stop |
| `]t` `[t` | Next / previous failed test |

Python (pytest and doctests), C/C++ (GoogleTest through CTest), Go and Rust are supported.

## Haskell

HLS runs through `~/.ghcup/bin/haskell-language-server-wrapper`, with
`~/.ghcup/bin` first in its PATH so it uses the GHC selected in GHCup (9.14.1).
HLS and GHC come from GHCup, not Mason.

Open a `.hs` or `.lhs` file for completion, hover (`K`), rename (`cd`), and code
actions (`g.`). Formatting on save and `<leader>cf` use HLS's formatter.

`<leader>rr`, `<leader>ra`, and `<leader>ro` open the current file in GHCi, in the
reused tmux run pane on the right (or a Neovim terminal split outside tmux).

`<leader>dd` debugs `main` with hdb (Well-Typed's haskell-debugger), which only works
with the GHC it was built for. Installed as `~/.local/share/hdb-0.14.0.0` with the
launcher `~/.local/bin/hdb` (it pins GHC 9.14.1). The program runs in a tmux pane,
which stays open after it ends. To install it again, take
`hdb-<version>-ghcup-x86_64-linux-unknown.tar.gz` from github.com/well-typed/haskell-debugger/releases.

## C/C++ build

- `<leader>bp` detects and builds CMake, Meson, Make, or Ninja projects.
- C/C++ test runs (`<leader>t…`, gutter ▶) build first, then ask CTest which binary
  holds each test, so the project needs `gtest_discover_tests`.

## Troubleshooting

- `:checkhealth` reports what is missing. Some warnings are expected: Snacks' image and
  scroll modules are off on purpose, and `gc`/`gcc` overlap by Neovim's design.
- `:Lazy` shows plugins, `:Mason` the installed tools, `:checkhealth vim.lsp` the attached servers.
- `<leader>n` shows past notifications. `:verbose nmap <key>` shows where a key is defined.
