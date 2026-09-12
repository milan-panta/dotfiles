#!/bin/bash
OPACITY_CONF="$HOME/.config/hypr/opacity.conf"

if grep -q "^windowrule" "$OPACITY_CONF"; then
    # Currently opaque → switch to transparent
    echo "" > "$OPACITY_CONF"
else
    # Currently transparent → switch to opaque
    echo "windowrule = opacity 1.0 1.0, match:class .*" > "$OPACITY_CONF"
fi

hyprctl reload
