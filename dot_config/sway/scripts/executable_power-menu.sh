#!/bin/sh
choice=$(printf '%s\n' Lock Logout Reboot Shutdown | wofi --dmenu --prompt 'Power')
[ -z "$choice" ] && exit 0
case "$choice" in
    Lock)     exec swaylock -f -i "$HOME/.config/sway/wallpaper.jpg" --clock --indicator ;;
    Logout)   exec swaymsg exit ;;
    Reboot)   exec reboot ;;
    Shutdown) exec poweroff ;;
esac
