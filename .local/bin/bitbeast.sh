#!/bin/sh

set -eu

# Ensure common user paths are available for Hyprland to find waybar/swaybg
export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/.nix-profile/bin:/usr/local/bin:/usr/bin:/bin:$PATH"

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

SCRIPT_REALPATH=$(readlink -f "$0" 2>/dev/null || realpath "$0" 2>/dev/null || echo "$0")
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "$SCRIPT_REALPATH")" && pwd)"
REPO_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"
if [ ! -d "$CONFIG_HOME/bitbeasts" ] && [ -d "$REPO_DIR/.config/bitbeasts" ]; then
    THEMES_DIR="$REPO_DIR/.config/bitbeasts"
    WALLPAPER_DIR="${BITBEAST_WALLPAPER_DIR:-$REPO_DIR}"
    WAYBAR_STYLES_DIR="$REPO_DIR/.config/waybar/styles"
else
    THEMES_DIR="$CONFIG_HOME/bitbeasts"
    WALLPAPER_DIR="${BITBEAST_WALLPAPER_DIR:-$DATA_HOME/bitbeast/wallpapers}"
    WAYBAR_STYLES_DIR="$CONFIG_HOME/waybar/styles"
fi

STATE_DIR="$CONFIG_HOME/bitbeast"
HYPR_DIR="$CONFIG_HOME/hypr"
WAYBAR_DIR="$CONFIG_HOME/waybar"
KITTY_DIR="$CONFIG_HOME/kitty"
ROFI_DIR="$CONFIG_HOME/rofi"
CAVA_DIR="$CONFIG_HOME/cava"
DEFAULT_WAYBAR_STYLE="${BITBEAST_DEFAULT_WAYBAR_STYLE:-hud}"

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
  bitbeast lock
  bitbeast avatar <path_to_image>
  bitbeast brightness [up|down]
  bitbeast visualizer

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

theme_color_hex() {
    colors_file=$1
    color_name=$2
    fallback=$3

    color_value=$(sed -n 's/^\$'"$color_name"'[[:space:]]*=[[:space:]]*rgb(\(.*\))/\1/p' "$colors_file" | tail -n 1)
    if [ -n "$color_value" ]; then
        printf '#%s\n' "$color_value"
    else
        printf '%s\n' "$fallback"
    fi
}

build_rofi_theme() {
    theme_dir=$1
    target_path=$2
    colors_file=$3
    require_file "$colors_file"

    bg=$(theme_color_hex "$colors_file" bg '#0a0b10')
    primary=$(theme_color_hex "$colors_file" primary '#00f2ff')
    secondary=$(theme_color_hex "$colors_file" secondary '#161925')
    accent=$(theme_color_hex "$colors_file" accent '#00f2ff')
    text=$(theme_color_hex "$colors_file" text '#e0e6ed')
    muted="${text}99"

    mkdir -p "$(dirname "$target_path")"
    cat > "$target_path" <<EOF_ROFI
* {
    bg: ${bg}f2;
    bg-alt: ${secondary}cc;
    primary: ${primary};
    accent: ${accent};
    text: ${text};
    muted: ${muted};
    urgent: #ff0055;
    border: 2px;
    spacing: 14px;
    font: "JetBrainsMono Nerd Font 11";
    background-color: transparent;
}

configuration {
    modi: "drun,run,window";
    show-icons: true;
    drun-display-format: "{name}";
}

window {
    location: center;
    anchor: center;
    width: 720px;
    border: @border;
    border-radius: 22px;
    border-color: @accent;
    background-color: @bg;
}

mainbox {
    children: [ inputbar, listview, mode-switcher ];
    spacing: 18px;
    padding: 22px;
}

inputbar {
    children: [ prompt, entry ];
    spacing: 12px;
    padding: 14px 18px;
    border-radius: 16px;
    background-color: @bg-alt;
    text-color: @text;
}

prompt {
    text-color: @accent;
}

entry {
    placeholder: "Ignite the launch";
    placeholder-color: @muted;
    text-color: @text;
}

listview {
    lines: 8;
    columns: 1;
    fixed-height: false;
    border: 0px;
    scrollbar: false;
}

element {
    padding: 12px 16px;
    border-radius: 16px;
    text-color: @text;
}

element normal.normal { background-color: transparent; text-color: @text; }
element selected.normal { background-color: @primary; text-color: @bg; }
element selected.active { background-color: @secondary; text-color: @text; }
element selected.urgent { background-color: @urgent; text-color: @bg; }
element alternate.normal { background-color: transparent; text-color: @text; }

element-icon { size: 28px; vertical-align: 0.5; background-color: transparent; }
element-text { text-color: inherit; vertical-align: 0.5; background-color: transparent; }

mode-switcher { spacing: 10px; }

button {
    padding: 10px 14px;
    border-radius: 999px;
    background-color: @bg-alt;
    text-color: @muted;
}

button selected { background-color: @primary; text-color: @bg; }
EOF_ROFI
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
        swww-daemon >/dev/null 2>&1 &
        # Wait for daemon to be fully ready (up to 5 seconds)
        _swww_tries=0
        while [ "$_swww_tries" -lt 10 ]; do
            sleep 0.5
            if swww query >/dev/null 2>&1; then
                return 0
            fi
            _swww_tries=$((_swww_tries + 1))
        done
        warn "swww-daemon started but may not be fully ready"
    fi

    return 0
}

apply_wallpaper_swww() {
    wallpaper_path=$1

    ensure_swww_daemon || return 1

    wallpaper_name=$(basename "$wallpaper_path")

    # Each BitBeast gets a unique, cinematic transition animation
    case "$wallpaper_name" in
        BurningCerbrus.png)
            # Fiery wave sweeping diagonally
            tr_type="wave";   tr_angle=45;  tr_step=60;  tr_duration=2;  tr_bezier=".25,.1,.25,1"
            ;;
        Dracel.png)
            # Ripple expanding from center
            tr_type="grow";   tr_angle=0;   tr_step=80;  tr_duration=3;  tr_bezier=".33,0,.67,1"
            ;;
        Dragoon.png)
            # Sweeping wipe like a storm front
            tr_type="wipe";   tr_angle=30;  tr_step=70;  tr_duration=2;  tr_bezier=".42,0,.58,1"
            ;;
        Dranzer.png)
            # Dramatic reveal from edges inward
            tr_type="outer";  tr_angle=0;   tr_step=50;  tr_duration=3;  tr_bezier=".16,1,.3,1"
            ;;
        Drigger.png)
            # Elegant fade with slow ease
            tr_type="simple"; tr_angle=0;   tr_step=3;   tr_duration=3;  tr_bezier=".22,.61,.36,1"
            ;;
        Galeon.png)
            # Burst from center outward
            tr_type="center"; tr_angle=0;   tr_step=90;  tr_duration=2;  tr_bezier=".65,0,.35,1"
            ;;
        *)
            # Random transition for unknown wallpapers
            tr_type="random"; tr_angle=0;   tr_step=90;  tr_duration=2;  tr_bezier=".42,0,.58,1"
            ;;
    esac

    attempt=1
    while [ "$attempt" -le 5 ]; do
        if swww img "$wallpaper_path" \
            --transition-type "$tr_type" \
            --transition-duration "$tr_duration" \
            --transition-fps 144 \
            --transition-angle "$tr_angle" \
            --transition-step "$tr_step" \
            --transition-bezier "$tr_bezier" \
            >/dev/null 2>&1; then
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

    # Prefer swww for its smooth animated transitions (wave, grow, wipe, etc.)
    if command -v swww >/dev/null 2>&1; then
        # Kill swaybg if switching backends
        pkill -x swaybg >/dev/null 2>&1 || true
        if apply_wallpaper_swww "$wallpaper_path"; then
            return 0
        fi
    fi

    # Fallback to swaybg (no transitions, hard cut)
    if command -v swaybg >/dev/null 2>&1; then
        if apply_wallpaper_swaybg "$wallpaper_path"; then
            return 0
        fi
    fi

    warn 'No wallpaper backend available. Install swww (recommended) or swaybg.'
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

reload_cava() {
    # Send SIGUSR1 to reload config live, or restart if not running
    if pgrep -x cava >/dev/null 2>&1; then
        pkill -SIGUSR1 -x cava >/dev/null 2>&1 || true
    fi
    # Also signal circular_cava.py if it's running
    if pgrep -f "circular_cava.py" >/dev/null 2>&1; then
        pkill -SIGUSR1 -f "circular_cava.py" >/dev/null 2>&1 || true
    fi
}

reload_kitty() {
    if command -v kitty >/dev/null 2>&1; then
        kitty @ set-colors -a "$KITTY_DIR/bitbeast.conf" >/dev/null 2>&1 || true
    fi
}

reload_hyprland() {
    if ! command -v hyprctl >/dev/null 2>&1; then
        warn 'hyprctl is not installed; Hyprland not reloaded.'
        return 1
    fi

    # Only attempt reload if Hyprland is actually running
    if [ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        return 0
    fi

    hyprctl reload >/dev/null 2>&1 || warn 'failed to reload Hyprland.'
}

reload_cursor() {
    colors_file=$1
    cursor_theme=$(sed -n 's/^\$cursor_theme[[:space:]]*=[[:space:]]*\(.*\)/\1/p' "$colors_file" | tail -n 1)
    if [ -n "$cursor_theme" ]; then
        # Apply cursor via hyprctl (live)
        hyprctl setcursor "$cursor_theme" 24 >/dev/null 2>&1 || true
        # Set environment variables for new windows
        hyprctl keyword env XCURSOR_THEME,"$cursor_theme" >/dev/null 2>&1 || true
        hyprctl keyword env XCURSOR_SIZE,24 >/dev/null 2>&1 || true
        # Persist via gsettings for GTK apps
        gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme" 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
    fi
}

restart_waybar() {
    if ! command -v waybar >/dev/null 2>&1; then
        warn 'waybar is not installed; Waybar not restarted.'
        return 1
    fi

    echo "Restarting Waybar natively..." >&2
    if pgrep -x waybar >/dev/null 2>&1; then
        pkill -SIGUSR2 -x waybar >/dev/null 2>&1 || true
    else
        waybar >/dev/null 2>&1 &
    fi
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
    build_rofi_theme "$theme_dir" "$ROFI_DIR/bitbeast.rasi" "$theme_dir/colors.conf"
    cp "$theme_dir/cava.conf" "$CAVA_DIR/config"
    printf '%s\n' "$theme_name" > "$STATE_DIR/current.theme"

    wallpaper_path=$(theme_wallpaper_path "$theme_dir")
    printf 'wallpaper="%s"\n' "$wallpaper_path" > "$STATE_DIR/wallpaper.conf"
    ensure_waybar_style || warn 'failed to sync Waybar style.'

    if [ "${BITBEAST_SKIP_RUNTIME:-0}" = "1" ]; then
        printf 'BitBeast theme activated: %s\n' "$theme_name"
        return 0
    fi

    # Restart Waybar first so the CSS swap is visible immediately.
    # Apply wallpaper synchronously, then reload other components.
    restart_waybar || true
    apply_wallpaper "$wallpaper_path" || true
    reload_kitty
    reload_cava
    reload_hyprland
    reload_cursor "$theme_dir/colors.conf"

    printf 'BitBeast theme activated: %s\n' "$theme_name"
}

pick_theme() {
    valid_themes=$(
        while IFS= read -r theme_name; do
            [ -n "$theme_name" ] || continue
            wallpaper_path=$(theme_wallpaper_path "$THEMES_DIR/$theme_name" 2>/dev/null) || continue
            [ -n "$wallpaper_path" ] || continue
            [ -f "$wallpaper_path" ] || continue
            printf '%s\n' "$theme_name"
        done <<EOF_LIST
$(list_themes)
EOF_LIST
    )

    [ -n "$valid_themes" ] || {
        printf 'No themes with valid wallpapers found.\n' >&2
        exit 1
    }

    chosen_file=$("$SCRIPT_DIR/bitbeast-wallpaper-selector" 2>/dev/null)
    [ -n "$chosen_file" ] || exit 0

    chosen_theme=""
    for t in $valid_themes; do
        w=$(theme_wallpaper_filename "$t" || true)
        if [ "$w" = "$chosen_file" ]; then
            chosen_theme=$t
            break
        fi
    done

    [ -n "$chosen_theme" ] || exit 0
    activate_theme "$chosen_theme"
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
    # Small delay to let Hyprland finish initializing
    sleep 1

    # First time launch safety net (if waybar theme is missing completely)
    if [ ! -f "$WAYBAR_DIR/bitbeast.css" ]; then
        theme_name=$(current_theme_name || echo "root")
        if [ "$theme_name" != "root" ]; then
            BITBEAST_SKIP_RUNTIME=1 activate_theme "$theme_name"
        else
            BITBEAST_SKIP_RUNTIME=1 activate_theme "dranzer"
        fi
    fi

    ensure_waybar_style || true
    restore_wallpaper || true
    restart_waybar || true

    # Apply the cursor theme from the current BitBeast theme
    theme_name=$(current_theme_name || echo "dranzer")
    theme_dir="$THEMES_DIR/$theme_name"
    if [ -f "$theme_dir/colors.conf" ]; then
        reload_cursor "$theme_dir/colors.conf"
    fi
}

brightness_control() {
    action=$1
    if command -v brightnessctl >/dev/null 2>&1; then
        if [ "$action" = "up" ]; then
            brightnessctl set 5%+
        else
            brightnessctl set 5%-
        fi
        return 0
    fi
    if command -v light >/dev/null 2>&1; then
        if [ "$action" = "up" ]; then
            light -A 5
        else
            light -U 5
        fi
        return 0
    fi
    backlight_dir=$(ls -d /sys/class/backlight/* 2>/dev/null | head -n 1)
    if [ -n "$backlight_dir" ] && [ -w "$backlight_dir/brightness" ]; then
        cur=$(cat "$backlight_dir/brightness")
        max=$(cat "$backlight_dir/max_brightness")
        step=$((max / 20))
        [ "$step" -eq 0 ] && step=1
        if [ "$action" = "up" ]; then
            new=$((cur + step))
            [ "$new" -gt "$max" ] && new=$max
        else
            new=$((cur - step))
            [ "$new" -lt 0 ] && new=0
        fi
        echo "$new" > "$backlight_dir/brightness"
        return 0
    fi
    warn "No brightness controller found (install brightnessctl)"
    return 1
}

set_avatar() {
    avatar_src=$1
    if [ ! -f "$avatar_src" ]; then
        printf 'Error: Avatar file not found: %s\n' "$avatar_src" >&2
        return 1
    fi
    mkdir -p "$STATE_DIR"
    cp "$avatar_src" "$STATE_DIR/avatar.png"
    printf 'Avatar updated successfully to %s\n' "$avatar_src"
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
    lock)
        # Prepare hyprlock colors file dynamically based on current theme
        theme_name=$(current_theme_name || echo "Dranzer")
        theme_name_upper=$(printf '%s' "$theme_name" | tr '[:lower:]' '[:upper:]')
        wallpaper_path=$(saved_wallpaper_path || fallback_wallpaper_path || echo "")
        
        # Read the current theme colors into lock config
        current_conf="$STATE_DIR/current.conf"
        target_lock_colors="$CONFIG_HOME/hypr/bitbeast-lock-colors.conf"
        
        [ -f "$current_conf" ] || current_conf="$THEMES_DIR/dranzer/colors.conf"
        
        bg_rgb=$(sed -n 's/^\$bg[[:space:]]*=[[:space:]]*rgb(\(.*\))/\1/p' "$current_conf" | tail -1)
        primary_rgb=$(sed -n 's/^\$primary[[:space:]]*=[[:space:]]*rgb(\(.*\))/\1/p' "$current_conf" | tail -1)
        secondary_rgb=$(sed -n 's/^\$secondary[[:space:]]*=[[:space:]]*rgb(\(.*\))/\1/p' "$current_conf" | tail -1)
        accent_rgb=$(sed -n 's/^\$accent[[:space:]]*=[[:space:]]*rgb(\(.*\))/\1/p' "$current_conf" | tail -1)
        text_rgb=$(sed -n 's/^\$text[[:space:]]*=[[:space:]]*rgb(\(.*\))/\1/p' "$current_conf" | tail -1)

        [ -n "$bg_rgb" ] || bg_rgb="0d0405"
        [ -n "$primary_rgb" ] || primary_rgb="f44336"
        [ -n "$secondary_rgb" ] || secondary_rgb="8d0b0b"
        [ -n "$accent_rgb" ] || accent_rgb="ffc107"
        [ -n "$text_rgb" ] || text_rgb="fff5f5"
        
        # Get glow color from waybar.css
        glow_hex="#ffd166" # fallback
        theme_dir="$THEMES_DIR/$theme_name"
        if [ -f "$theme_dir/waybar.css" ]; then
            glow_match=$(grep '@define-color glow' "$theme_dir/waybar.css" | awk '{print $3}' | tr -d ';')
            [ -n "$glow_match" ] && glow_hex="$glow_match"
        fi

        # Find avatar path (prefer config avatar, then user face, fallback to wallpaper)
        if [ -f "$STATE_DIR/avatar.png" ]; then
            avatar_path="$STATE_DIR/avatar.png"
        elif [ -f "$HOME/.face.icon" ]; then
            avatar_path="$HOME/.face.icon"
        elif [ -f "$HOME/.face" ]; then
            avatar_path="$HOME/.face"
        else
            avatar_path="$wallpaper_path"
        fi
        
        mkdir -p "$CONFIG_HOME/hypr"
        cat > "$target_lock_colors" <<EOF_COLORS
\$bg = rgb(${bg_rgb})
\$primary = rgb(${primary_rgb})
\$secondary = rgb(${secondary_rgb})
\$accent = rgb(${accent_rgb})
\$text = rgb(${text_rgb})
\$text_soft = rgba(${text_rgb}dd)
\$text_dim = rgba(${text_rgb}99)
\$glow = rgb(${glow_hex#\#})
\$glow_alpha = ${glow_hex#\#}
\$panel = rgba(${bg_rgb}d8)
\$panel_soft = rgba(${bg_rgb}96)
\$surface = rgba(${bg_rgb}ea)
\$surface_alt = rgba(${bg_rgb}b8)
\$line = rgba(${glow_hex#\#}55)
\$wallpaper_path = $wallpaper_path
\$theme_name = $theme_name_upper
\$avatar_path = $avatar_path
\$user_display_name = $USER
EOF_COLORS

        hyprlock --config "$CONFIG_HOME/hypr/hyprlock.conf"
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
    avatar)
        [ $# -eq 2 ] || { usage; exit 1; }
        set_avatar "$2"
        ;;
    brightness)
        [ $# -eq 2 ] || { usage; exit 1; }
        brightness_control "$2"
        ;;
    visualizer)
        theme_name=$(current_theme_name || echo "dranzer")
        theme_dir="$THEMES_DIR/$theme_name"
        colors_file="$theme_dir/colors.conf"
        [ -f "$colors_file" ] || colors_file="$THEMES_DIR/dranzer/colors.conf"
        
        bg=$(theme_color_hex "$colors_file" bg '#0a0a0a')
        primary=$(theme_color_hex "$colors_file" primary '#e8450c')
        secondary=$(theme_color_hex "$colors_file" secondary '#7b120f')
        accent=$(theme_color_hex "$colors_file" accent '#ffd166')
        text=$(theme_color_hex "$colors_file" text '#fff1dd')
        
        # Pass theme colors to the visualizer with bars mode, huge radius and more bars/dots
        "$SCRIPT_DIR/circular_cava.py" --mode bars --radius 14 --bars 80 "$bg" "$secondary" "$primary" "$accent" "$text"
        ;;
    *)
        if [ $# -ne 1 ]; then
            usage
            exit 1
        fi
        activate_theme "$command_name"
        ;;
esac
