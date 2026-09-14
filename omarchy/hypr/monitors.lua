-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local omarchy_gdk_scale = 2
local external_4k_scale = 2

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.env("STEAM_FORCE_DESKTOPUI_SCALING", tostring(external_4k_scale))

-- Hyprland 0.56.2 can disconnect every Wayland client when a hotplugged
-- output with a specific monitor rule is removed and immediately re-added.
-- Keep hot-plugged displays on the catch-all rule to avoid that destructive
-- output replacement path. Use 2x for the 27-inch 4K panel, then override only
-- the permanently attached laptop panel with its comfortable 1.5x scale.
hl.monitor({ output = "", mode = "preferred", position = "0x0", scale = 2 })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "1920x0", scale = 1.5 })

-- Stable workspace ranges, matched to the LG itself rather than its dock port.
for workspace = 1, 10 do
  hl.workspace_rule({
    workspace = tostring(workspace),
    monitor = workspace <= 5 and "desc:LG Electronics LG ULTRAFINE 208NTFADU731" or "eDP-1",
    default = workspace == 1 or workspace == 6,
    persistent = true,
  })
end
