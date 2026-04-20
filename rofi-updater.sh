#!/bin/sh

set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
THEME_DIR="$SCRIPT_DIR/.config/bitbeasts"

updated=0

for f in "$THEME_DIR"/*/rofi.rasi; do
    [ -f "$f" ] || continue

    # Glass-like alpha on 6-digit bg colors.
    sed -i -E 's/(bg:[[:space:]]*#[0-9a-fA-F]{6})[0-9a-fA-F]{2};/\17a;/g' "$f"

    # Keep styling tweaks to properties Rofi actually supports.
    sed -i 's/border-radius: 22px;/border-radius: 28px;/g' "$f"
    sed -i 's/padding: 22px;/padding: 32px;/g' "$f"
    sed -i 's/padding: 14px 18px;/padding: 18px 22px;/g' "$f"

    updated=1
done

if [ "$updated" -eq 1 ]; then
    printf 'Updated BitBeast rofi theme templates in %s\n' "$THEME_DIR"
else
    printf 'No rofi.rasi files found in %s\n' "$THEME_DIR" >&2
fi
