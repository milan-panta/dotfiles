# dotfiles

Modular dotfiles for **macOS** and **Omarchy** (Arch Linux / Hyprland).

## Structure

```text
dotfiles/
├── common/             # Shared across both macOS and Omarchy
│   ├── nvim/           # Neovim configuration
│   ├── yazi/           # Yazi file manager
│   ├── lazygit/        # Lazygit
│   ├── mpv/            # MPV video player
│   ├── gh-dash/        # GitHub CLI dashboard
│   ├── tridactyl/      # Firefox Tridactyl bindings
│   ├── vimium-c/       # Browser Vimium-C profiles
│   └── home/           # Files symlinked to $HOME (e.g. .ideavimrc)
│
├── mac/                # macOS-specific configurations
│   ├── alacritty/      # Alacritty (Command keys, macOS font sizes)
│   ├── btop/           # btop with Apple GPU & gruvbox
│   ├── ghostty/        # Ghostty with macOS Command user-keys
│   ├── git/            # macOS Git settings (delta, codediff)
│   ├── starship.toml   # Custom multi-language Starship prompt
│   ├── tmux/           # Tmux (Cmd user-keys, pbcopy, gruvbox)
│   ├── yabai/          # macOS tiling window manager
│   ├── skhd/           # macOS hotkey daemon
│   └── home/           # macOS shell files (.zshrc, .zprofile)
│
├── omarchy/            # Omarchy-specific configurations
│   ├── alacritty/      # Alacritty (Omarchy dynamic theme)
│   ├── btop/           # btop (Omarchy dynamic theme)
│   ├── ghostty/        # Ghostty (epoll backend, Omarchy dynamic theme)
│   ├── git/            # Omarchy Git settings (Delta pager, gh helper, codediff)
│   ├── hypr/           # Hyprland (window manager, keybindings, monitors)
│   ├── starship.toml   # Omarchy prompt
│   └── tmux/           # Tmux (Alt keys, Omarchy theme, move-pane.sh)
│
└── sync.sh             # Zero-dependency symlink sync script
```

## Quick Start

To apply the dotfiles for your current system:

```bash
./sync.sh
```

### Options

* **Dry run** (preview changes without applying):
  ```bash
  ./sync.sh --dry-run
  ```
* **Force a specific platform**:
  ```bash
  ./sync.sh --platform mac
  ./sync.sh --platform omarchy
  ```

