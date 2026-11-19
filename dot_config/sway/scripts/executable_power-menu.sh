#!/bin/sh
choice=$(printf '%s\n' Lock Logout Reboot Shutdown | wofi --dmenu --prompt 'Power')
[ -z "$choice" ] && exit 0
case "$choice" in
    Lock)     exec swaylock -f -i "$HOME/Pictures/apod-latest.jpg" --clock --indicator ;;
    Logout)   exec swaymsg exit ;;
    Reboot)   exec /usr/local/bin/busybox-reboot ;;
    Shutdown) exec /usr/local/bin/busybox-poweroff ;;
esac
