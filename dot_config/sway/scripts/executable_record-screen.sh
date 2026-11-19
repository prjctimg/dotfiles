#!/bin/sh
# Toggle screen recording (Super+X).
# First press starts wf-recorder; second press stops it and finalizes the file.
dir="$HOME/Videos/Recordings"
mkdir -p "$dir"

if pgrep -x wf-recorder >/dev/null 2>&1; then
	# SIGINT lets wf-recorder close the muxer cleanly so the file is playable.
	pkill -INT -x wf-recorder
	exit 0
fi

file="$dir/$(date +%Y%m%d-%H%M%S).mp4"
exec wf-recorder -c libx264 -f "$file"
