#!/bin/bash
# Focus the running mpv window (switching rift workspace if needed), or start mpv.
set -euo pipefail

if ! pgrep -x mpv >/dev/null; then
  exec /opt/homebrew/bin/mpv --idle
fi

id="$(rift-cli query workspaces |
  jq -c 'first(.[].windows[] | select(.app_name == "mpv") | .id) // empty')"
if [ -n "$id" ]; then
  rift-cli execute window focus --window-id "$id"
else
  # Not managed by rift on the active display (e.g. another monitor): let macOS raise it.
  osascript -e 'tell application "System Events" to set frontmost of (first process whose name is "mpv") to true'
fi
