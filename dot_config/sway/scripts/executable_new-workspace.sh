#!/bin/sh
# new-workspace.sh — create/switch to the next unused Sway desktop.
# Sway creates workspaces on demand; this picks the lowest free number so F12
# always gives a fresh desktop instead of jumping to an existing one.

set -u
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
export PATH

used=$(swaymsg -t get_workspaces 2>/dev/null | jq -r '.[].num' 2>/dev/null | sort -n | tr '\n' ' ')

i=1
while [ "$i" -le 99 ]; do
    case " $used " in
        *" $i "*) i=$((i + 1)) ;;
        *) exec swaymsg "workspace number $i" ;;
    esac
done
