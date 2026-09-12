#!/usr/bin/env bash
# Dotfiles symlink sync script for macOS and Omarchy
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
mkdir -p "$CONFIG_DIR"

DRY_RUN=false
OVERRIDE_PLATFORM=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    --platform)
      OVERRIDE_PLATFORM="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./sync.sh [--dry-run] [--platform mac|omarchy]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -n "$OVERRIDE_PLATFORM" ]]; then
  PLATFORM="$OVERRIDE_PLATFORM"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  PLATFORM="mac"
else
  PLATFORM="omarchy"
fi

TIMESTAMP="$(date +%Y%m%d%H%M%S)"

link_item() {
  local src="$1"
  local dest="$2"

  if [ -L "$dest" ]; then
    local current_target
    current_target="$(readlink -f "$dest" 2>/dev/null || readlink "$dest")"
    local desired_target
    desired_target="$(readlink -f "$src" 2>/dev/null || readlink "$src")"

    if [ "$current_target" = "$desired_target" ]; then
      echo "  [OK]   $dest"
      return 0
    fi

    if [ "$DRY_RUN" = true ]; then
      echo "  [REPLACE SYMLINK] $dest (currently -> $current_target) => $src"
      return 0
    fi
    rm "$dest"
  elif [ -e "$dest" ]; then
    if [ "$DRY_RUN" = true ]; then
      echo "  [BACKUP & LINK] $dest => $dest.bak.$TIMESTAMP, link -> $src"
      return 0
    fi
    echo "  [BAK]  Backing up $dest -> $dest.bak.$TIMESTAMP"
    mv "$dest" "$dest.bak.$TIMESTAMP"
  fi

  if [ "$DRY_RUN" = true ]; then
    echo "  [LINK] $dest -> $src"
  else
    ln -s "$src" "$dest"
    echo "  [LINK] $dest -> $src"
  fi
}

link_dir() {
  local source_dir="$1"
  local target_base="$2"

  [ -d "$source_dir" ] || return 0

  for item in "$source_dir"/*; do
    [ -e "$item" ] || continue
    local name
    name="$(basename "$item")"
    if [ "$name" = "home" ]; then
      continue
    fi
    link_item "$item" "$target_base/$name"
  done

  if [ -d "$source_dir/home" ]; then
    shopt -s nullglob dotglob
    for item in "$source_dir/home"/*; do
      [ -e "$item" ] || continue
      local name
      name="$(basename "$item")"
      [ "$name" = "." ] || [ "$name" = ".." ] && continue
      link_item "$item" "$HOME/$name"
    done
    shopt -u dotglob nullglob
  fi
}

echo "==> Syncing dotfiles (Platform: $PLATFORM, Dry-run: $DRY_RUN)"
echo "--- Linking common configs to $CONFIG_DIR ---"
link_dir "$DOTFILES_DIR/common" "$CONFIG_DIR"

echo "--- Linking $PLATFORM configs to $CONFIG_DIR ---"
link_dir "$DOTFILES_DIR/$PLATFORM" "$CONFIG_DIR"

echo "==> Finished successfully!"
