#!/bin/sh
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y%m%d-%H%M%S).png"
grim -g "$(slurp)" "$file" && wl-copy <"$file"
