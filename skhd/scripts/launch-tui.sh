#!/bin/bash
set -euo pipefail
export PATH="/opt/homebrew/bin:/usr/local/bin:$PATH"

LABEL="float_$$_$RANDOM"

yabai -m rule --add label="$LABEL" app="Ghostty" manage=off

/Applications/Ghostty.app/Contents/MacOS/ghostty -e "$@" &
PID=$!

yabai -m signal --add \
  label="$LABEL" \
  event=window_created \
  app=Ghostty \
  action="
    if [ \"\$(yabai -m query --windows --window \$YABAI_WINDOW_ID | jq '.pid')\" = \"$PID\" ]; then
      yabai -m window \$YABAI_WINDOW_ID --grid 5:5:1:1:3:3
      yabai -m signal --remove $LABEL
      yabai -m rule --remove $LABEL
    fi"

sleep 3 && yabai -m signal --remove "$LABEL" 2>/dev/null && yabai -m rule --remove "$LABEL" 2>/dev/null &
