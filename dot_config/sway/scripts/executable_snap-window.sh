#!/bin/sh
# ChromeOS-style Alt+[ / Alt+] docking.
# A tiled window cannot be "docked" directly in stock Sway, so the
# focused window is floated and sized to the requested half of the
# focused output. Running the same side twice restores tiling.
side="$1"

if [ "$(swaymsg -t get_tree | jq -r '.. | objects | select(.focused == true) | .type' | head -1)" = "floating_con" ]; then
    swaymsg -q 'floating disable'
    exit 0
fi

swaymsg -q 'floating enable'
swaymsg -q 'resize set 50 ppt 100 ppt'
case "$side" in
    left)  swaymsg -q 'move position 0 0' ;;
    right) swaymsg -q 'move position 50 ppt 0' ;;
esac
