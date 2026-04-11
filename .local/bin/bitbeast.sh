#!/bin/sh

set -eu

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE_DIR="$CONFIG_HOME/bitbeast"
THEMES_DIR="$CONFIG_HOME/bitbeasts"
HYPR_DIR="$CONFIG_HOME/hypr"
WAYBAR_DIR="$CONFIG_HOME/waybar"
WAYBAR_STYLES_DIR="$WAYBAR_DIR/styles"
KITTY_DIR="$CONFIG_HOME/kitty"
ROFI_DIR="$CONFIG_HOME/rofi"
CAVA_DIR="$CONFIG_HOME/cava"
WALLPAPER_DIR="${BITBEAST_WALLPAPER_DIR:-$DATA_HOME/bitbeast/wallpapers}"
DEFAULT_WAYBAR_STYLE="${BITBEAST_DEFAULT_WAYBAR_STYLE:-ember}"

usage() {
    cat >&2 <<EOF_USAGE
Usage:
  bitbeast <theme-name>
  bitbeast list
  bitbeast pick
  bitbeast style <style-name>
  bitbeast style list
  bitbeast style cycle
  bitbeast pick-style
  bitbeast current-theme
  bitbeast current-style
  bitbeast restore-wallpaper
  bitbeast session-init

Available themes:
EOF_USAGE
    list_themes >&2
    cat >&2 <<EOF_STYLES

Available Waybar styles:
EOF_STYLES
    list_styles >&2
}

warn() {
    printf 'Warning: %s\n' "$1" >&2
}

list_themes() {
    for dir in "$THEMES_DIR"/*; do
        [ -d "$dir" ] || continue
        basename "$dir"
    done | LC_ALL=C sort
}

list_styles() {
    for file_path in "$WAYBAR_STYLES_DIR"/*.css; do
        [ -f "$file_path" ] || continue
        basename "$file_path" .css
    done | LC_ALL=C sort
}

require_file() {
    file_path=$1
    if [ ! -f "$file_path" ]; then
        printf 'Missing required file: %s\n' "$file_path" >&2
        exit 1
    fi
}

resolve_wallpaper_path() {
    wallpaper_value=$1

    case $wallpaper_value in
        @wallpapers/*)
            printf '%s/%s\n' "$WALLPAPER_DIR" "${wallpaper_value#@wallpapers/}"
            ;;
        ~/*)
            printf '%s/%s\n' "$HOME" "${wallpaper_value#~/}"
            ;;
        *)
            printf '%s\n' "$wallpaper_value"
            ;;
    esac
}

theme_wallpaper_filename() {
    theme_name=$1

    case $theme_name in
        burningcerbrus) printf 'BurningCerbrus.png\n' ;;
        draciel) printf 'Dracel.png\n' ;;
        dragoon) printf 'Dragoon.png\n' ;;
        dranzer) printf 'Dranzer.png\n' ;;
        driger) printf 'Drigger.png\n' ;;
        galeon) printf 'Galeon.png\n' ;;
        *) return 1 ;;
    esac
}

theme_wallpaper_path() {
    theme_dir=$1

    require_file "$theme_dir/wallpaper.conf"

    wallpaper_value=$(sed -n 's/^[[:space:]]*wallpaper[[:space:]]*=[[:space:]]*//p' "$theme_dir/wallpaper.conf" | tail -n 1)
    wallpaper_value=$(printf '%s' "$wallpaper_value" | sed 's/^"//; s/"$//')

    if [ -z "$wallpaper_value" ]; then
        printf 'Wallpaper path is empty in %s\n' "$theme_dir/wallpaper.conf" >&2
        exit 1
    fi

    wallpaper_path=$(resolve_wallpaper_path "$wallpaper_value")

    if [ ! -f "$wallpaper_path" ]; then
        printf 'Wallpaper file not found: %s\n' "$wallpaper_path" >&2
        exit 1
    fi

    printf '%s\n' "$wallpaper_path"
}

current_theme_name() {
    if [ -f "$STATE_DIR/current.theme" ]; then
        sed -n '1p' "$STATE_DIR/current.theme"
    fi
}

current_style_name() {
    if [ -f "$STATE_DIR/current.style" ]; then
        sed -n '1p' "$STATE_DIR/current.style" | tr '[:upper:]' '[:lower:]'
        return 0
    fi

    printf '%s\n' "$DEFAULT_WAYBAR_STYLE"
}

style_variant_path() {
    style_name=$1
    style_name=$(printf '%s' "$style_name" | tr '[:upper:]' '[:lower:]')
    style_path="$WAYBAR_STYLES_DIR/$style_name.css"

    if [ ! -f "$style_path" ]; then
        printf 'Unknown Waybar style: %s\n' "$style_name" >&2
        return 1
    fi

    printf '%s\n' "$style_path"
}

write_active_style() {
    style_name=$1
    style_file=$(style_variant_path "$style_name") || return 1

    mkdir -p "$STATE_DIR" "$WAYBAR_DIR"
    cp "$style_file" "$WAYBAR_DIR/bitbeast-style.css"
    printf '%s\n' "$(basename "$style_file" .css)" > "$STATE_DIR/current.style"
}

ensure_waybar_style() {
    style_name=$(current_style_name)

    if write_active_style "$style_name" >/dev/null 2>&1; then
        return 0
    fi

    write_active_style "$DEFAULT_WAYBAR_STYLE"
}

saved_wallpaper_path() {
    if [ ! -f "$STATE_DIR/wallpaper.conf" ]; then
        return 1
    fi

    wallpaper_value=$(sed -n 's/^[[:space:]]*wallpaper[[:space:]]*=[[:space:]]*//p' "$STATE_DIR/wallpaper.conf" | tail -n 1)
    wallpaper_value=$(printf '%s' "$wallpaper_value" | sed 's/^"//; s/"$//')

    [ -n "$wallpaper_value" ] || return 1
    resolve_wallpaper_path "$wallpaper_value"
}

fallback_wallpaper_path() {
    theme_name=$(current_theme_name || true)
    [ -n "$theme_name" ] || return 1

    wallpaper_name=$(theme_wallpaper_filename "$theme_name" || true)
    [ -n "$wallpaper_name" ] || return 1

    wallpaper_path="$WALLPAPER_DIR/$wallpaper_name"
    [ -f "$wallpaper_path" ] || return 1
    printf '%s\n' "$wallpaper_path"
}

ensure_swww_daemon() {
    if ! command -v swww >/dev/null 2>&1; then
        return 1
    fi

    if ! pgrep -x swww-daemon >/dev/null 2>&1; then
        swww-daemon --format xrgb >/dev/null 2>&1 &
        sleep 1
    fi

    return 0
}

apply_wallpaper_swww() {
    wallpaper_path=$1

    ensure_swww_daemon || return 1

    attempt=1
    while [ "$attempt" -le 5 ]; do
        if swww img "$wallpaper_path" --transition-type any --transition-duration 1 >/dev/null 2>&1; then
            return 0
        fi

        sleep 1
        attempt=$((attempt + 1))
    done

    return 1
}

apply_wallpaper_swaybg() {
    wallpaper_path=$1

    if ! command -v swaybg >/dev/null 2>&1; then
        return 1
    fi

    # Kill any existing swaybg instance
    pkill -x swaybg >/dev/null 2>&1 || true
    sleep 0.2

    swaybg -i "$wallpaper_path" -m fill >/dev/null 2>&1 &
    return 0
}

apply_wallpaper() {
    wallpaper_path=$1

    if [ ! -f "$wallpaper_path" ]; then
        warn "wallpaper file not found: $wallpaper_path"
        return 1
    fi

    # Use swaybg as requested (alternative to swww)
    if command -v swaybg >/dev/null 2>&1; then
        if apply_wallpaper_swaybg "$wallpaper_path"; then
            return 0
        fi
    fi

    # Fallback to swww only if swaybg is missing
    if command -v swww >/dev/null 2>&1; then
        if apply_wallpaper_swww "$wallpaper_path"; then
            return 0
        fi
    fi

    warn 'No wallpaper backend available. Install swaybg or swww.'
    return 1
}

restore_wallpaper() {
    wallpaper_path=$(saved_wallpaper_path || true)
    theme_name=$(current_theme_name || true)

    if [ -z "$wallpaper_path" ] || [ ! -f "$wallpaper_path" ]; then
        if [ -n "$theme_name" ] && [ -d "$THEMES_DIR/$theme_name" ]; then
            wallpaper_path=$(theme_wallpaper_path "$THEMES_DIR/$theme_name" || true)
        fi
    fi

    if [ -z "$wallpaper_path" ] || [ ! -f "$wallpaper_path" ]; then
        wallpaper_path=$(fallback_wallpaper_path || true)
    fi

    [ -n "$wallpaper_path" ] || return 1
    apply_wallpaper "$wallpaper_path"
}

reload_kitty() {
    if command -v kitty >/dev/null 2>&1; then
        kitty @ set-colors -a "$KITTY_DIR/bitbeast.conf" >/dev/null 2>&1 || true
    fi
}

reload_hyprland() {
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl reload >/dev/null 2>&1 || warn 'failed to reload Hyprland.'
    else
        warn 'hyprctl is not installed; Hyprland not reloaded.'
    fi
}

restart_waybar() {
    if ! command -v waybar >/dev/null 2>&1; then
        warn 'waybar is not installed; Waybar not restarted.'
        return 1
    fi

    if command -v systemctl >/dev/null 2>&1 && \
        systemctl --user list-unit-files waybar.service --no-legend 2>/dev/null | grep -q '^waybar\.service'
    then
        systemctl --user restart waybar.service >/dev/null 2>&1 && return 0
    fi

    pkill -x waybar >/dev/null 2>&1 || true
    waybar >/dev/null 2>&1 &
}

activate_style() {
    style_name=$1

    write_active_style "$style_name"

    if [ "${BITBEAST_SKIP_RUNTIME:-0}" = "1" ]; then
        printf 'Waybar style activated: %s\n' "$(current_style_name)"
        return 0
    fi

    restart_waybar || true
    printf 'Waybar style activated: %s\n' "$(current_style_name)"
}

activate_theme() {
    theme_name=$1
    theme_name=$(printf '%s' "$theme_name" | tr '[:upper:]' '[:lower:]')
    theme_dir="$THEMES_DIR/$theme_name"

    if [ ! -d "$theme_dir" ]; then
        printf 'Unknown BitBeast theme: %s\n' "$theme_name" >&2
        usage
        exit 1
    fi

    require_file "$theme_dir/colors.conf"
    require_file "$theme_dir/hyprland.conf"
    require_file "$theme_dir/waybar.css"
    require_file "$theme_dir/kitty.conf"
    require_file "$theme_dir/rofi.rasi"
    require_file "$theme_dir/cava.conf"

    mkdir -p "$STATE_DIR" "$HYPR_DIR" "$WAYBAR_DIR" "$KITTY_DIR" "$ROFI_DIR" "$CAVA_DIR"

    cp "$theme_dir/colors.conf" "$STATE_DIR/current.conf"
    cp "$theme_dir/hyprland.conf" "$HYPR_DIR/bitbeast-theme.conf"
    cp "$theme_dir/waybar.css" "$WAYBAR_DIR/bitbeast.css"
    cp "$theme_dir/kitty.conf" "$KITTY_DIR/bitbeast.conf"
    cp "$theme_dir/rofi.rasi" "$ROFI_DIR/bitbeast.rasi"
    cp "$theme_dir/cava.conf" "$CAVA_DIR/config"
    printf '%s\n' "$theme_name" > "$STATE_DIR/current.theme"

    wallpaper_path=$(theme_wallpaper_path "$theme_dir")
    printf 'wallpaper="%s"\n' "$wallpaper_path" > "$STATE_DIR/wallpaper.conf"
    ensure_waybar_style || warn 'failed to sync Waybar style.'

    if [ "${BITBEAST_SKIP_RUNTIME:-0}" = "1" ]; then
        printf 'BitBeast theme activated: %s\n' "$theme_name"
        return 0
    fi

    apply_wallpaper "$wallpaper_path" || true
    reload_kitty
    reload_hyprland
    restart_waybar || true

    printf 'BitBeast theme activated: %s\n' "$theme_name"
}

pick_theme() {
    if ! command -v rofi >/dev/null 2>&1; then
        printf 'rofi is required for bitbeast pick\n' >&2
        exit 1
    fi

    selection=$(
        while IFS= read -r theme_name; do
            [ -n "$theme_name" ] || continue
            wallpaper_path=$(theme_wallpaper_path "$THEMES_DIR/$theme_name")
            # Present strictly the wallpaper name options to the user
            printf '%s\n' "$(basename "$wallpaper_path")"
        done <<EOF_LIST
$(list_themes)
EOF_LIST
    )

    choice=$(printf '%s\n' "$selection" | rofi -dmenu -i -p "Select Wallpaper")
    chosen_wallpaper=$(printf '%s' "$choice")

    [ -n "$chosen_wallpaper" ] || exit 0
    
    # Map the selected wallpaper back to the corresponding theme automatically
    chosen_theme=""
    while IFS= read -r theme_name; do
        [ -n "$theme_name" ] || continue
        wallpaper_path=$(theme_wallpaper_path "$THEMES_DIR/$theme_name")
        if [ "$(basename "$wallpaper_path")" = "$chosen_wallpaper" ]; then
            chosen_theme="$theme_name"
            break
        fi
    done <<EOF_LIST
$(list_themes)
EOF_LIST

    if [ -n "$chosen_theme" ]; then
        activate_theme "$chosen_theme"
    fi
}

cycle_style() {
    styles=$(list_styles)
    [ -n "$styles" ] || {
        printf 'No Waybar styles available in %s\n' "$WAYBAR_STYLES_DIR" >&2
        exit 1
    }

    current_style=$(current_style_name)
    next_style=
    first_style=
    found_current=0

    for style_name in $styles; do
        [ -n "$first_style" ] || first_style=$style_name

        if [ "$found_current" -eq 1 ]; then
            next_style=$style_name
            break
        fi

        if [ "$style_name" = "$current_style" ]; then
            found_current=1
        fi
    done

    [ -n "$next_style" ] || next_style=$first_style
    activate_style "$next_style"
}

pick_style() {
    if ! command -v rofi >/dev/null 2>&1; then
        printf 'rofi is required for bitbeast pick-style\n' >&2
        exit 1
    fi

    current_style=$(current_style_name)
    selection=$(
        while IFS= read -r style_name; do
            [ -n "$style_name" ] || continue
            if [ "$style_name" = "$current_style" ]; then
                printf '%s\tactive\n' "$style_name"
            else
                printf '%s\tstyle\n' "$style_name"
            fi
        done <<EOF_STYLE_LIST
$(list_styles)
EOF_STYLE_LIST
    )

    [ -n "$selection" ] || {
        printf 'No Waybar styles available in %s\n' "$WAYBAR_STYLES_DIR" >&2
        exit 1
    }

    choice=$(printf '%s\n' "$selection" | rofi -dmenu -i -p "Waybar style")
    chosen_style=$(printf '%s' "$choice" | cut -f1)

    [ -n "$chosen_style" ] || exit 0
    activate_style "$chosen_style"
}

session_init() {
    ensure_waybar_style || true
    restore_wallpaper || true
    restart_waybar || true
}

command_name=${1:-}

if [ $# -eq 0 ]; then
    usage
    exit 1
fi

case $command_name in
    list)
        list_themes
        ;;
    pick)
        pick_theme
        ;;
    style)
        if [ $# -lt 2 ]; then
            usage
            exit 1
        fi

        case $2 in
            list)
                list_styles
                ;;
            cycle)
                cycle_style
                ;;
            *)
                [ $# -eq 2 ] || {
                    usage
                    exit 1
                }
                activate_style "$2"
                ;;
        esac
        ;;
    pick-style)
        pick_style
        ;;
    current-theme)
        current_theme_name
        ;;
    current-style)
        current_style_name
        ;;
    restore-wallpaper)
        restore_wallpaper
        ;;
    session-init)
        session_init
        ;;
    *)
        if [ $# -ne 1 ]; then
            usage
            exit 1
        fi
        activate_theme "$command_name"
        ;;
esac
