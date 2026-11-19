#!/bin/sh
# Puppy Linux desktop integration for Sway.
# Equivalent to ~/.config/labwc/autostart, so Sway is a full replacement
# for the default window manager: spot-user sockets, Xauthority, theming,
# D-Bus environment, and Puppy's delayed/autostart services.

# Let applications running as 'spot' talk to Sway and Xwayland.
SPOT_RUNTIME_DIR=`run-as-spot sh -c 'mkdir -p $XDG_RUNTIME_DIR && echo $XDG_RUNTIME_DIR'`
for F in $WAYLAND_DISPLAY $WAYLAND_DISPLAY.lock; do
	umount -l $SPOT_RUNTIME_DIR/$F 2>/dev/null
	touch $SPOT_RUNTIME_DIR/$F
	chown spot:spot $XDG_RUNTIME_DIR/$F
	mount --bind $XDG_RUNTIME_DIR/$F $SPOT_RUNTIME_DIR/$F
done

# Xauthority for Xwayland clients (root and spot).
echo "add $DISPLAY . `mcookie`" | xauth -q -f ~/.Xauthority
cp -f ~/.Xauthority /home/spot/.Xauthority
chown spot:spot /home/spot/.Xauthority

# Apply Puppy's monitor layout preferences.
[ -e "$XDG_CONFIG_HOME/wmonitors/wmon_cmd" ] && . $XDG_CONFIG_HOME/wmonitors/wmon_cmd

# Apply Puppy's GTK theme settings for both users.
. /etc/rc.d/wl_func
apply_gtk_settings

# Pass the Wayland session environment to D-Bus activated applications.
dbus-update-activation-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_RUNTIME_DIR DBUS_SESSION_BUS_ADDRESS
run-as-spot dbus-update-activation-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# Show all window buttons in CSD apps such as Firefox.
gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close"
run-as-spot gsettings set org.gnome.desktop.wm.preferences button-layout "appmenu:minimize,maximize,close"

# Clipboard history for spot (root's watchers are declared in the sway config).
run-as-spot sh -c 'type cliphist >/dev/null 2>&1 && wl-paste --watch cliphist store &'

# GTK2 theme follows the same settings as GTK3.
export GTK2_RC_FILES=$HOME/.gtkrc-2.0

# Drop stale gamma adjustment instances from a previous session.
pgrep gammastep >/dev/null 2>&1 && kill -9 $(pgrep gammastep)

# Tap-only Super/Meta opens the apps menu. Sway cannot bind a bare modifier
# without also firing on every Super chord, so a tiny evdev monitor handles it.
if [ ! -x /usr/local/bin/super-tap ] && command -v cc >/dev/null 2>&1; then
	cc -O2 -Wall -o /usr/local/bin/super-tap "$HOME/.config/sway/scripts/super-tap.c" >/dev/null 2>&1
fi
[ -x /usr/local/bin/super-tap ] && /usr/local/bin/super-tap &

# Launch Puppy's autostart applications and delayed services.
xdg_autostart.sh
# Puppy's default sfwbar taskbar duplicates Waybar and squashes windows;
# keep it out of the Sway session (labwc still uses it).
pkill -x sfwbar 2>/dev/null || true
/usr/sbin/delayedrun &
