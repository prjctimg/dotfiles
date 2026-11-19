#!/bin/sh
sel=$(cliphist list | wofi --dmenu --prompt 'Clipboard')
[ -z "$sel" ] && exit 0
printf '%s' "$sel" | cliphist decode | wl-copy
