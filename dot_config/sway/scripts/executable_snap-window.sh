#!/bin/sh
# ChromeOS-style Alt+[ / Alt+] docking.
# Dock the focused window to exactly half the active desktop at full workspace
# height. Workspace coords are used, so Waybar and outer gaps are respected.
# Pressing the same side again restores tiling; pressing the other side moves
# the floating window across.

side="$1"

focused=$(swaymsg -t get_tree 2>/dev/null |
    jq -c '.. | objects | select(.focused == true and (.type == "con" or .type == "floating_con")) | {type, rect}' |
    head -1)

type=$(printf '%s\n' "$focused" | jq -r '.type // "con"')
win_x=$(printf '%s\n' "$focused" | jq -r '.rect.x // 0')

dock() {
    target_side=$1
    rect=$(swaymsg -t get_workspaces 2>/dev/null |
        jq -c '.[] | select(.focused == true) | .rect')
    ws_x=$(printf '%s\n' "$rect" | jq -r '.x // 0')
    w=$(printf '%s\n' "$rect" | jq -r '.width // 1366')
    h=$(printf '%s\n' "$rect" | jq -r '.height // 768')
    half=$((w / 2))
    gap=10
    pane=$((half - gap))

    swaymsg -q "resize set ${pane}px ${h}px"
    case "$target_side" in
        left)  swaymsg -q 'move position 0 0' ;;
        right) swaymsg -q "move position $((half + gap)) 0" ;;
    esac
}

if [ "$type" = "floating_con" ]; then
    # Work out which half the window currently occupies.
    rect=$(swaymsg -t get_workspaces 2>/dev/null |
        jq -c '.[] | select(.focused == true) | .rect')
    ws_x=$(printf '%s\n' "$rect" | jq -r '.x // 0')
    w=$(printf '%s\n' "$rect" | jq -r '.width // 1366')
    mid=$((ws_x + w / 2))

    if [ "$win_x" -lt "$mid" ]; then
        current=left
    else
        current=right
    fi

    if [ "$current" = "$side" ]; then
        swaymsg -q 'floating disable'
        exit 0
    fi

    dock "$side"
    exit 0
fi

swaymsg -q 'floating enable'
sleep 0.3
dock "$side"
