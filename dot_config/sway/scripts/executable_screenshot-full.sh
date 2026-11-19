#!/bin/sh
dir="$HOME/Pictures/Screenshots"
mkdir -p "$dir"
file="$dir/$(date +%Y%m%d-%H%M%S).png"
grim "$file" && wl-copy <"$file"
