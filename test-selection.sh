#!/bin/bash
export XDG_CONFIG_HOME="$HOME/.config"
source /home/sniperxamster/Downloads/Dranzer/.local/bin/bitbeast.sh >/dev/null 2>&1
while IFS= read -r theme_name; do
    [ -n "$theme_name" ] || continue
    wallpaper_path=$(theme_wallpaper_path "$THEMES_DIR/$theme_name" 2>/dev/null) || continue
    [ -n "$wallpaper_path" ] || continue
    printf '%s\n' "$(basename "$wallpaper_path")"
done <<EOF_LIST
$(list_themes)
EOF_LIST
