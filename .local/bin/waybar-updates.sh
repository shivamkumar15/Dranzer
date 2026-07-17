#!/usr/bin/env bash
# Compact package-updates indicator for Waybar: +12(3)
set -u

repo=0
aur=0

if command -v checkupdates >/dev/null 2>&1; then
  repo=$(checkupdates 2>/dev/null | wc -l | tr -d ' ')
fi

if command -v yay >/dev/null 2>&1; then
  aur=$(yay -Qua 2>/dev/null | wc -l | tr -d ' ')
elif command -v paru >/dev/null 2>&1; then
  aur=$(paru -Qua 2>/dev/null | wc -l | tr -d ' ')
fi

repo=${repo:-0}
aur=${aur:-0}

if (( repo + aur == 0 )); then
  printf '{"text":"󰏗 0","tooltip":"System is up to date","class":"updated"}\n'
else
  printf '{"text":"󰏗 +%s(%s)","tooltip":"%s repo · %s AUR updates","class":"updates"}\n' \
    "$repo" "$aur" "$repo" "$aur"
fi
