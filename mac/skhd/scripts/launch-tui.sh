#!/bin/bash
# Open a TUI in its own Ghostty window. The fixed "tui-popup" title matches an
# app rule in ~/.config/rift/config.toml that floats and centers the window.
set -euo pipefail

exec /Applications/Ghostty.app/Contents/MacOS/ghostty --title="tui-popup: $1" -e "$@"
