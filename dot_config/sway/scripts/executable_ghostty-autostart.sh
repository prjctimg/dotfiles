#!/bin/sh
# Launch the startup Ghostty window as a floating, centered window so the
# APOD wallpaper stays visible on the desktop. Windows opened later with
# Meta+a keep Sway's normal tiling behavior.

set -u
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

/usr/bin/ghostty &
term_pid=$!

# Wait for the window to appear in Sway.
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    swaymsg -t get_tree 2>/dev/null |
        jq -e '.. | select(.app_id? == "com.mitchellh.ghostty") | .id' >/dev/null 2>&1 && break
    sleep 0.5
done

if command -v swaymsg >/dev/null 2>&1 && [ -n "${WAYLAND_DISPLAY:-}" ]; then
    swaymsg '[app_id="com.mitchellh.ghostty"] floating enable' >/dev/null 2>&1
    swaymsg '[app_id="com.mitchellh.ghostty"] resize set 1000 620' >/dev/null 2>&1
    swaymsg '[app_id="com.mitchellh.ghostty"] move position center' >/dev/null 2>&1
fi

wait "$term_pid"
