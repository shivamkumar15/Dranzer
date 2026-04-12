#!/bin/bash
backlight_dir=$(ls -d /sys/class/backlight/* 2>/dev/null | head -n 1)
if [ -n "$backlight_dir" ] && [ -r "$backlight_dir/brightness" ]; then
    cur=$(cat "$backlight_dir/brightness")
    max=$(cat "$backlight_dir/max_brightness")
    step=$((max / 20))
    [ "$step" -eq 0 ] && step=1
    new=$((cur + step))
    [ "$new" -gt "$max" ] && new=$max
    echo "Current: $cur, Max: $max, Step: $step, New: $new"
else
    echo "No backlight found or not readable"
fi
