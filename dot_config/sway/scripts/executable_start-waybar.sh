#!/bin/sh
# Restart waybar cleanly on Sway reload.
pkill -x waybar 2>/dev/null
exec waybar
