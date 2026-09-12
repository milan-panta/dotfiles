#!/usr/bin/env bash
# Move current tmux pane to target window by index (clamped to highest window index)

target="$1"

# Ensure target is an integer
if ! [[ "$target" =~ ^[0-9]+$ ]]; then
  exit 0
fi

curr_win=$(tmux display-message -p "#{window_index}")
max_win=$(tmux list-windows -F "#{window_index}" | sort -n | tail -1)

# Clamp to the last window if greater than max window index
if [ "$target" -gt "$max_win" ]; then
  target="$max_win"
fi

if [ "$target" -lt 1 ]; then
  target=1
fi

if [ "$target" -eq "$curr_win" ]; then
  tmux display-message "Pane is already in window $target"
  exit 0
fi

# Join side-by-side (-h) into target window
tmux join-pane -h -t ":$target"
