#!/usr/bin/env bash
# JoeOS: makes a still picture for every live wallpaper (video) in ~/Videos/Wallpapers.
# The pictures are used in the wallpaper picker, for the bar colours and on the lock screen.
# They're saved in ~/.cache/joeos/live-thumbs as <video file name>.jpg. Needs ffmpeg.
set -u

SRC="$HOME/Videos/Wallpapers"
OUT="$HOME/.cache/joeos/live-thumbs"
mkdir -p "$SRC" "$OUT"
command -v ffmpeg >/dev/null 2>&1 || { echo "NOFFMPEG"; exit 0; }

shopt -s nullglob nocaseglob
for v in "$SRC"/*.{mp4,webm,mkv,mov}; do
    t="$OUT/$(basename "$v").jpg"
    [ -s "$t" ] && [ "$t" -nt "$v" ] && continue
    # a frame from 1 second in (or the very first frame for very short clips)
    ffmpeg -y -loglevel error -ss 1 -i "$v" -frames:v 1 -vf "scale=1280:-2" "$t" 2>/dev/null \
        || ffmpeg -y -loglevel error -i "$v" -frames:v 1 -vf "scale=1280:-2" "$t" 2>/dev/null
done
echo "DONE"
