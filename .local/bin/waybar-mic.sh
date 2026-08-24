#!/usr/bin/env bash
# Mic status for Waybar — icon reflects source mute state.
set -u

if command -v wpctl >/dev/null 2>&1; then
    out=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
    if [[ "$out" == *MUTED* ]]; then
        printf '{"text": "󰍭", "tooltip": "Microphone muted", "class": "muted"}\n'
    else
        printf '{"text": "󰍬", "tooltip": "Microphone on", "class": "on"}\n'
    fi
    exit 0
fi

out=$(pactl get-source-mute @DEFAULT_SOURCE@ 2>/dev/null)
if [[ "$out" == *yes* ]]; then
    printf '{"text": "󰍭", "tooltip": "Microphone muted", "class": "muted"}\n'
else
    printf '{"text": "󰍬", "tooltip": "Microphone on", "class": "on"}\n'
fi
