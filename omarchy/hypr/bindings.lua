-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Focus window navigation with HJKL (vim keys)
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")

o.bind("SUPER + H", "Focus on left window", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Focus on below window", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Focus on above window", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus on right window", hl.dsp.focus({ direction = "r" }))

-- Swap window navigation with SUPER + SHIFT + HJKL (vim keys)
hl.unbind("SUPER + SHIFT + K")

o.bind("SUPER + SHIFT + H", "Swap window to the left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Swap window to the right", hl.dsp.window.swap({ direction = "r" }))

-- Remapped displaced default actions to logical alternatives
o.bind("SUPER + ALT + J", "Toggle window split", hl.dsp.layout("togglesplit"))
o.bind("SUPER + ALT + L", "Toggle workspace layout", "omarchy-hyprland-workspace-layout-toggle")

-- Toggle globally between the two most recently focused windows
hl.unbind("SUPER + TAB")
o.bind("SUPER + TAB", "Switch to last active window", hl.dsp.focus({ last = true }))

-- Replace Omarchy's Herdr shortcut with the standard keybinding searcher
hl.unbind("SUPER + CTRL + K")
o.bind("SUPER + CTRL + K", "Keybindings", "omarchy-menu-keybindings")

-- Toggle floating and center window so it respects screen geometry and top bar
hl.unbind("SUPER + T")
o.bind("SUPER + T", "Toggle window floating/tiling", function()
  hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
  hl.dispatch(hl.dsp.window.center())
end)

-- Launch Codex TUI without approvals or sandboxing
hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + X", "Codex (yolo mode)", "omarchy-launch-tui codex --dangerously-bypass-approvals-and-sandbox")

-- Launch Gemini TUI without approvals or sandboxing
hl.unbind("SUPER + SHIFT + G")
o.bind("SUPER + SHIFT + G", "Gemini (yolo mode)", "omarchy-launch-tui agy --dangerously-skip-permissions")

-- Launch the installed Google Calendar app
hl.unbind("SUPER + CTRL + ALT + D")
o.bind("SUPER + SHIFT + C", "Calendar", { launch = "gtk-launch Calendar" })

-- Restore tmux binding disabled with the preinstalled application bindings
o.bind("SUPER + ALT + RETURN", "Tmux", { omarchy = "terminal-tmux" })

-- Open Neovim in the shared Work tmux session
hl.unbind("SUPER + SHIFT + N")
o.bind("SUPER + SHIFT + N", "Neovim (tmux)", "omarchy-launch-terminal bash -lc 'if tmux has-session -t Work 2>/dev/null; then tmux new-window -t Work nvim && exec tmux attach-session -t Work; else exec tmux new-session -s Work nvim; fi'")

-- Open private notes in Neovim inside a dedicated tmux session in Ghostty
o.bind("SUPER + SHIFT + O", "Private notes (Ghostty + tmux)", "setsid uwsm-app -- ghostty --working-directory=/home/mln/Documents/Notes/Private -e bash -lc 'if tmux has-session -t Notes 2>/dev/null; then tmux new-window -t Notes -c /home/mln/Documents/Notes/Private nvim && exec tmux attach-session -t Notes; else exec tmux new-session -s Notes -c /home/mln/Documents/Notes/Private nvim; fi'")

-- Screenshot (same action as PrintScreen)
o.bind("SUPER + SHIFT + S", "Screenshot", "omarchy-capture-screenshot")


-- Universal media controls on the ThinkPad Fn+F9-F11 hotkey layer.
-- Plain F9-F11 remain available to applications as standard function keys.
o.bind("XF86NotificationCenter", "Previous track", "omarchy-shell media previous", { locked = true })
o.bind("XF86PickupPhone", "Play/pause", "omarchy-shell media playPause", { locked = true })
o.bind("XF86HangupPhone", "Next track", "omarchy-shell media next", { locked = true })
