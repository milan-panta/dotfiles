#!/usr/bin/env bash
# Move the current pane to window N (prefix m, then N). You follow the pane.
#   - Window N exists: the pane joins it, side by side.
#   - No window N: the pane becomes a new window, numbered one past the highest.

target=$1
[[ $target =~ ^[0-9]+$ ]] || exit 0

read -r pane curr_win panes < <(tmux display-message -p '#{pane_id} #{window_index} #{window_panes}')
max_win=$(tmux list-windows -F '#{window_index}' | sort -n | tail -1)

if ((target == curr_win)); then
  tmux display-message "Pane is already in window $target"
elif tmux list-windows -F '#{window_index}' | grep -qx "$target"; then
  # By pane id: if this was the window's last pane, the windows after it renumber.
  tmux join-pane -h -s "$pane" -t ":$target" \; select-window -t "$pane"
elif ((panes == 1)); then
  # Already alone in its window: just move that window to the end.
  ((curr_win == max_win)) || tmux move-window -t ":$((max_win + 1))"
else
  tmux break-pane -t ":$((max_win + 1))"
fi
