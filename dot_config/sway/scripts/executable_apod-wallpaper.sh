#!/bin/sh
# apod-wallpaper.sh — NASA Astronomy Picture of the Day wallpaper.
#
# Downloads each day's APOD image directly into ~/Pictures so it can be
# browsed/previewed from the file manager, maintains ~/Pictures/apod-latest.jpg
# as a symlink to the newest image, and applies that symlink as the Sway
# background. If NASA (or the network) is unreachable, the most recently saved
# APOD image is reused, so the desktop always has a wallpaper.
#
# Usage:
#   apod-wallpaper.sh            fetch/apply once
#   apod-wallpaper.sh --force    ignore today's cached image and refetch
#   apod-wallpaper.sh --daemon   refresh every 6 hours (used from sway config)

set -u

HOME_DIR=${HOME:-/root}
APOD_DIR="${XDG_PICTURES_DIR:-$HOME_DIR/Pictures}"
WALLPAPER="$APOD_DIR/apod-latest.jpg"
LOCK="$HOME_DIR/.local/share/apod-wallpaper.lock"
LOG="$HOME_DIR/.local/share/apod-wallpaper.log"
API_KEY=${NASA_APOD_API_KEY:-DEMO_KEY}
API_URL="https://api.nasa.gov/planetary/apod?api_key=$API_KEY&thumbs=true"

mkdir -p "$APOD_DIR" "$(dirname "$LOCK")" 2>/dev/null

log() {
    printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >>"$LOG" 2>/dev/null
}

if [ -f "$LOG" ] && [ "$(wc -l <"$LOG" 2>/dev/null)" -gt 200 ]; then
    tail -n 150 "$LOG" >"$LOG.tmp" 2>/dev/null && mv -f "$LOG.tmp" "$LOG" 2>/dev/null
fi

if [ "${1:---once}" = "--daemon" ]; then
    # Singleton by PID file. A lock is not held while sleeping: an orphaned
    # `sleep` child would otherwise keep it and block every future reload.
    PIDFILE="$HOME_DIR/.local/share/apod-wallpaper-daemon.pid"
    if [ -s "$PIDFILE" ]; then
        old_pid=$(cat "$PIDFILE" 2>/dev/null)
        if [ -n "$old_pid" ] && kill -0 "$old_pid" 2>/dev/null &&
           tr '\0' ' ' <"/proc/$old_pid/cmdline" 2>/dev/null | grep -q 'apod-wallpaper.sh --daemon'; then
            exit 0
        fi
    fi
    printf '%s\n' "$$" >"$PIDFILE" 2>/dev/null
    trap 'rm -f "$PIDFILE"' EXIT HUP INT TERM
    log "APOD wallpaper daemon started"
    while :; do
        "$0" --once
        sleep 21600
    done
fi

# One fetch at a time; the daemon and a manual run must not race.
exec 9>"$LOCK" || exit 0
if ! flock -n 9; then
    log "another APOD fetch is running; skipping"
    exit 0
fi

DAY=$(date +%F)
TMP_META="$APOD_DIR/.apod-meta.$$.tmp"
TMP_IMG="$APOD_DIR/.apod-image.$$.tmp"
trap 'rm -f "$TMP_META" "$TMP_IMG"' EXIT HUP INT TERM

apply_wallpaper() {
    img=$1
    [ -f "$img" ] || return 1
    # Point a stable symlink at the dated image, then ask Sway to use it.
    ln -sfn "$(basename "$img")" "$WALLPAPER" 2>/dev/null || return 1
    if command -v swaymsg >/dev/null 2>&1 && [ -n "${WAYLAND_DISPLAY:-}" ]; then
        swaymsg "output * bg $WALLPAPER fill" >/dev/null 2>&1
    fi
    # zzzfm's desktop manager paints its own wallpaper and would otherwise
    # cover Sway's background, so keep it pointed at the same APOD symlink.
    if command -v zzzfm >/dev/null 2>&1 && [ -n "${WAYLAND_DISPLAY:-}" ]; then
        zzzfm --set-wallpaper "$WALLPAPER" >/dev/null 2>&1
    fi
    log "wallpaper applied: $img"
    return 0
}

newest_cached() {
    newest=
    # Only APOD files named YYYY-MM-DD.* — never other Pictures content or
    # the apod-latest symlink itself.
    for f in "$APOD_DIR"/20[0-9][0-9]-[0-9][0-9]-[0-9][0-9].*; do
        [ -f "$f" ] || continue
        case "$f" in *.txt) continue ;; esac
        if [ -z "$newest" ] || [ "$f" -nt "$newest" ]; then
            newest=$f
        fi
    done
    [ -n "$newest" ] && printf '%s\n' "$newest"
}

# Already fetched today? Just make sure the active wallpaper points at it.
for f in "$APOD_DIR/$DAY".*; do
    if [ -f "$f" ] && [ "${1:---once}" != "--force" ]; then
        case "$f" in *.txt) continue ;; esac
        apply_wallpaper "$f" && exit 0
    fi
done

log "fetching $DAY APOD metadata"
if ! curl -fsSL --connect-timeout 10 --max-time 40 "$API_URL" -o "$TMP_META" 2>>"$LOG"; then
    # The public API occasionally returns 500/503. The APOD site is a
    # second NASA-hosted source for the same picture.
    log "NASA API unavailable; trying the APOD website"
    site_img=$(curl -fsSL --connect-timeout 10 --max-time 40 \
        https://apod.nasa.gov/apod/astropix.html 2>>"$LOG" |
        sed -n 's/.*<meta property="og:image" content="\([^"]*\)".*/\1/p' | head -n 1)
    if [ -n "$site_img" ] && curl -fsSL --connect-timeout 10 --max-time 90 \
        "$site_img" -o "$TMP_IMG" 2>>"$LOG"; then
        mime=$(file -b --mime-type "$TMP_IMG" 2>/dev/null)
        case "$mime" in
            image/*)
                mv -f "$TMP_IMG" "$APOD_DIR/$DAY.jpg" 2>/dev/null || exit 0
                printf '%s - NASA Astronomy Picture of the Day\nSource: https://apod.nasa.gov/apod/astropix.html\n' "$DAY" \
                    >"$APOD_DIR/$DAY.txt" 2>/dev/null
                apply_wallpaper "$APOD_DIR/$DAY.jpg"
                exit 0
                ;;
        esac
    fi
    log "APOD sources unreachable; reusing last saved image"
    last=$(newest_cached)
    [ -n "$last" ] && apply_wallpaper "$last"
    exit 0
fi

media_type=$(jq -r '.media_type // empty' "$TMP_META" 2>/dev/null)
img_url=$(jq -r 'if .media_type == "image" then (.hdurl // .url // empty) else (.thumbnail_url // empty) end' "$TMP_META" 2>/dev/null)

if [ -z "$img_url" ]; then
    log "APOD entry has no downloadable image (media_type=$media_type); reusing last saved image"
    last=$(newest_cached)
    [ -n "$last" ] && apply_wallpaper "$last"
    exit 0
fi

base=${img_url%%\?*}
case "$base" in
    *.png)  ext=png ;;
    *.webp) ext=webp ;;
    *.jpeg) ext=jpeg ;;
    *)      ext=jpg ;;
esac
target="$APOD_DIR/$DAY.$ext"

log "downloading $img_url"
if ! curl -fsSL --connect-timeout 10 --max-time 90 "$img_url" -o "$TMP_IMG" 2>>"$LOG"; then
    log "image download failed; reusing last saved image"
    last=$(newest_cached)
    [ -n "$last" ] && apply_wallpaper "$last"
    exit 0
fi

mime=$(file -b --mime-type "$TMP_IMG" 2>/dev/null)
case "$mime" in
    image/*) ;;
    *)
        log "downloaded file is not an image ($mime); reusing last saved image"
        last=$(newest_cached)
        [ -n "$last" ] && apply_wallpaper "$last"
        exit 0
        ;;
esac

mv -f "$TMP_IMG" "$target" 2>/dev/null || { log "cannot save $target"; exit 0; }
# Keep a small text companion so the file manager shows what the picture is.
jq -r '"\(.date) - \(.title)\n\(.copyright // "NASA/APOD")\n\n\(.explanation // "")"' \
    "$TMP_META" >"$APOD_DIR/$DAY.txt" 2>/dev/null

apply_wallpaper "$target"
exit 0
