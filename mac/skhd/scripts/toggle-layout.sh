#!/bin/bash
# Toggle the active rift workspace between bsp tiling and floating.
set -euo pipefail

mode="$(rift-cli query workspaces | jq -r '.[] | select(.is_active) | .layout_mode')"
if [ "$mode" = "bsp" ]; then
  rift-cli execute workspace set-layout floating
else
  rift-cli execute workspace set-layout bsp
fi
