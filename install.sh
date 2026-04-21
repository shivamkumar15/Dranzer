#!/usr/bin/env bash

set -eu

REPO_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
BIN_DIR="${XDG_BIN_HOME:-$HOME/.local/bin}"

THEMES_SRC_DIR="$REPO_DIR/.config/bitbeasts"
THEMES_DEST_DIR="$CONFIG_HOME/bitbeasts"
STATE_DIR="$CONFIG_HOME/bitbeast"
WALLPAPER_DEST_DIR="$DATA_HOME/bitbeast/wallpapers"
BACKUP_ROOT="$STATE_HOME/bitbeast-installer/backups/$(date +%Y%m%d-%H%M%S)"
BACKUPS_CREATED=0
APPLY_RUNTIME=0
FORCE=0
DEFAULT_THEME=$(sed -n '1p' "$REPO_DIR/.config/bitbeast/current.theme")
THEME_NAME=${DEFAULT_THEME:-dranzer}
WALLPAPER_SRC_FILES="
BurningCerbrus.png
Dracel.png
Dragoon.png
Dranzer.png
Drigger.png
Galeon.png
"

check_dependencies() {
    missing=0

    # Required
    for cmd in waybar rofi kitty hyprlock swaync playerctl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            printf '\033[1;31m✗ Required:\033[0m %s is not installed\n' "$cmd" >&2
            missing=1
        fi
    done

    # Wallpaper backend (at least one required)
    if ! command -v swaybg >/dev/null 2>&1 && ! command -v swww >/dev/null 2>&1; then
        printf '\033[1;31m✗ Required:\033[0m No wallpaper backend found. Install swww (recommended) or swaybg\n' >&2
        missing=1
    fi

    # Recommended
    for cmd in brightnessctl wpctl grim slurp wl-copy; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            printf '\033[1;33m⚠ Optional:\033[0m %s is not installed (some keybindings will not work)\n' "$cmd" >&2
        fi
    done

    if [ "$missing" -eq 1 ]; then
        printf '\n\033[1;33mInstall missing required dependencies before continuing.\033[0m\n' >&2
        printf 'Continue anyway? [y/N] ' >&2
        read -r confirm
        case $confirm in
            [yY]*) ;;
            *) exit 1 ;;
        esac
    fi
}


usage() {
    cat <<EOF
Usage: ./install.sh [--theme <name>] [--apply] [--force]

Options:
  --theme <name>  Install and activate a specific BitBeast theme.
  --apply         Reload live desktop components after install.
  --force         Overwrite existing files without creating backups.
  -h, --help      Show this help message.
EOF
}

ensure_theme_exists() {
    theme_dir=$1
    if [ ! -d "$THEMES_SRC_DIR/$theme_dir" ]; then
        printf 'Unknown BitBeast theme: %s\n' "$theme_dir" >&2
        exit 1
    fi
}

backup_path() {
    target_path=$1

    if [ "$FORCE" -eq 1 ]; then
        rm -rf "$target_path"
        return
    fi

    if [ ! -e "$target_path" ] && [ ! -L "$target_path" ]; then
        return
    fi

    relative_path=${target_path#"$HOME"/}
    backup_target="$BACKUP_ROOT/$relative_path"
    mkdir -p "$(dirname "$backup_target")"
    mv "$target_path" "$backup_target"
    BACKUPS_CREATED=1
}

install_file() {
    source_path=$1
    target_path=$2

    mkdir -p "$(dirname "$target_path")"

    if [ -f "$target_path" ] && cmp -s "$source_path" "$target_path"; then
        return
    fi

    backup_path "$target_path"
    cp "$source_path" "$target_path"
}

install_dir() {
    source_path=$1
    target_path=$2

    if [ -d "$target_path" ] && diff -qr "$source_path" "$target_path" >/dev/null 2>&1; then
        return
    fi

    if [ -d "$target_path" ] || [ -e "$target_path" ] || [ -L "$target_path" ]; then
        backup_path "$target_path"
    fi

    mkdir -p "$(dirname "$target_path")"
    cp -R "$source_path" "$target_path"
}

while [ $# -gt 0 ]; do
    case $1 in
        --theme)
            [ $# -ge 2 ] || {
                printf 'Missing value for --theme\n' >&2
                exit 1
            }
            THEME_NAME=$2
            shift 2
            ;;
        --apply)
            APPLY_RUNTIME=1
            shift
            ;;
        --force)
            FORCE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            printf 'Unknown option: %s\n' "$1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

setup_zsh() {
    ZSH_DIR="$HOME/.oh-my-zsh"
    ZSHRC="$HOME/.zshrc"

    if [ ! -d "$ZSH_DIR" ]; then
        printf '\033[1;33m⚠ Oh My Zsh not found. Skipping zsh setup.\033[0m\n'
        return
    fi

    printf '\n\033[1;36m=== Zsh Theme Selection ===\033[0m\n'
    printf 'Select a theme for your terminal:\n\n'

    themes=(
        "powerlevel10k:Powerlevel10k (Popular, feature-rich, icons)"
        "robbyrussell:Robbyrussell (Default, clean)"
        "agnoster:Agnoster (Segments, needs powerline fonts)"
        "YS:YS (Minimal, good colors)"
        "lambda:Lambda (Minimal, git info)"
        "minimal:Minimal (Ultra clean)"
        "pi:Pi (Japanese style)"
        "avit:Avit (Compact, shows time)"
        "kennethreitz:Kenneth Reitz (Python dev)"
        "fishy:Fishy (Fish shell style)"
        "steeef:steeef (Green, git-aware)"
        "candy:Candy (Colorful)"
        "wedisagree:We disagree (Dark theme)"
        "sunaku:Sunaku (Clean, patched)"
        "smt:SMT (Simple)"
        "frisk:Frisk (Pastel)"
        "sorin:Sorin (Clean)"
        "emotty:Emotty (Emoji-based)"
        "gallois:Gallois (French)"
    )

    for i in "${!themes[@]}"; do
        idx=$((i + 1))
        desc="${themes[$i]#*:}"
        printf '  \033[1;33m%2d\033[0m. %s\n' "$idx" "$desc"
    done

    printf '\n  \033[1;33m20\033[0m. Skip zsh setup\n'
    printf '\nEnter selection [1-20] (default: 1): '
    read -r choice

    choice=${choice:-1}

    case $choice in
        20|[Nn]*) printf 'Skipping zsh setup.\n'; return ;;
        *)
            if ! printf '%s\n' "$choice" | grep -qE '^[0-9]+$' || [ "$choice" -lt 1 ] || [ "$choice" -gt 19 ]; then
                printf 'Invalid selection. Using default (Powerlevel10k).\n'
                choice=1
            fi
            SELECTED_THEME="${themes[$((choice - 1))]%%:*}"
            ;;
    esac

    mkdir -p "$ZSH_DIR/custom/themes"
    mkdir -p "$ZSH_DIR/plugins"

    if [ "$SELECTED_THEME" = "powerlevel10k" ]; then
        if [ ! -d "$ZSH_DIR/custom/themes/powerlevel10k" ]; then
            printf 'Installing Powerlevel10k...\n'
            git clone --depth 1 https://github.com/romkatv/powerlevel10k.git "$ZSH_DIR/custom/themes/powerlevel10k"
        else
            printf 'Updating Powerlevel10k...\n'
            (cd "$ZSH_DIR/custom/themes/powerlevel10k" && git pull)
        fi
    fi

    if [ ! -d "$ZSH_DIR/plugins/zsh-autosuggestions" ]; then
        printf 'Installing zsh-autosuggestions...\n'
        git clone --depth 1 https://github.com/zsh-users/zsh-autosuggestions.git "$ZSH_DIR/plugins/zsh-autosuggestions"
    else
        printf 'Updating zsh-autosuggestions...\n'
        (cd "$ZSH_DIR/plugins/zsh-autosuggestions" && git pull)
    fi

    if [ ! -d "$ZSH_DIR/plugins/zsh-syntax-highlighting" ]; then
        printf 'Installing zsh-syntax-highlighting...\n'
        git clone --depth 1 https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_DIR/plugins/zsh-syntax-highlighting"
    else
        printf 'Updating zsh-syntax-highlighting...\n'
        (cd "$ZSH_DIR/plugins/zsh-syntax-highlighting" && git pull)
    fi

    if [ -f "$ZSHRC" ]; then
        backup_path "$ZSHRC"
    fi

    if [ "$SELECTED_THEME" = "powerlevel10k" ]; then
        cat > "$ZSHRC" << EOF
# If you come from bash you might have to change your \$PATH.
# export PATH=\$HOME/bin:\$HOME/.local/bin:/usr/local/bin:\$PATH

# Path to your Oh My Zsh installation.
export ZSH="\$HOME/.oh-my-zsh"

ZSH_THEME="$SELECTED_THEME/$SELECTED_THEME"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Enable Powerlevel10k instant prompt
if [[ -r "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh" ]]; then
  source "\${XDG_CACHE_HOME:-\$HOME/.cache}/p10k-instant-prompt-\${(%):-%n}.zsh"
fi

source \$ZSH/oh-my-zsh.sh

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF

        cat > "$HOME/.p10k.zsh" << 'EOF'
typeset -g POWERLEVEL9K_MODE=nerdfont-complete
typeset -g POWERLEVEL9K_INSTANT_PROMPT=quiet
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs newline prompt_char)
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time background_jobs context time)
typeset -g POWERLEVEL9K_DIR_TRUNCATION_STRATEGY=truncate_to_last
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=1
typeset -g POWERLEVEL9K_STATUS_OK=false
typeset -g POWERLEVEL9K_VCS_CLEAN_FOREGROUND=76
typeset -g POWERLEVEL9K_VCS_DIRTY_FOREGROUND=196
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_FOREGROUND=76
typeset -g POWERLEVEL9K_PROMPT_CHAR_ERROR_FOREGROUND=196
EOF
    else
        cat > "$ZSHRC" << EOF
# If you come from bash you might have to change your \$PATH.
# export PATH=\$HOME/bin:\$HOME/.local/bin:/usr/local/bin:\$PATH

# Path to your Oh My Zsh installation.
export ZSH="\$HOME/.oh-my-zsh"

ZSH_THEME="$SELECTED_THEME"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

source \$ZSH/oh-my-zsh.sh
EOF
    fi

    printf 'Zsh configured with %s and plugins.\n' "$SELECTED_THEME"
}

setup_zsh

mkdir -p "$BIN_DIR" "$STATE_DIR" "$WALLPAPER_DEST_DIR"

install_dir "$THEMES_SRC_DIR" "$THEMES_DEST_DIR"
install_dir "$REPO_DIR/.config/waybar/styles" "$CONFIG_HOME/waybar/styles"

for wallpaper_name in $WALLPAPER_SRC_FILES; do
    install_file "$REPO_DIR/$wallpaper_name" "$WALLPAPER_DEST_DIR/$wallpaper_name"
done

install_file "$REPO_DIR/.config/bitbeast/current.style" "$STATE_DIR/current.style"
install_file "$REPO_DIR/.config/hypr/hyprland.conf" "$CONFIG_HOME/hypr/hyprland.conf"
install_file "$REPO_DIR/.config/hypr/hyprlock.conf" "$CONFIG_HOME/hypr/hyprlock.conf"
install_dir "$REPO_DIR/.config/waybar/modules" "$CONFIG_HOME/waybar/modules"
install_dir "$REPO_DIR/.config/waybar/includes" "$CONFIG_HOME/waybar/includes"
install_file "$REPO_DIR/.config/waybar/theme.css" "$CONFIG_HOME/waybar/theme.css"
install_file "$REPO_DIR/.config/waybar/style.css" "$CONFIG_HOME/waybar/style.css"
install_file "$REPO_DIR/.config/waybar/bitbeast-style.css" "$CONFIG_HOME/waybar/bitbeast-style.css"
install_file "$REPO_DIR/.config/waybar/config.jsonc" "$CONFIG_HOME/waybar/config.jsonc"
install_file "$REPO_DIR/.config/kitty/kitty.conf" "$CONFIG_HOME/kitty/kitty.conf"
install_file "$REPO_DIR/.config/rofi/config.rasi" "$CONFIG_HOME/rofi/config.rasi"
install_dir "$REPO_DIR/.config/swaync" "$CONFIG_HOME/swaync"
install_dir "$REPO_DIR/web-wallpaper-selector" "$DATA_HOME/bitbeast/web-wallpaper-selector"
install_file "$REPO_DIR/.local/bin/bitbeast.sh" "$BIN_DIR/bitbeast"
install_file "$REPO_DIR/.local/bin/bitbeast-battery" "$BIN_DIR/bitbeast-battery"
install_file "$REPO_DIR/.local/bin/bitbeast-media" "$BIN_DIR/bitbeast-media"
install_file "$REPO_DIR/.local/bin/bitbeast-session" "$BIN_DIR/bitbeast-session"
install_file "$REPO_DIR/.local/bin/bitbeast-wallpaper-selector" "$BIN_DIR/bitbeast-wallpaper-selector"
install_file "$REPO_DIR/.local/bin/circular_cava.py" "$BIN_DIR/circular_cava.py"
chmod +x "$BIN_DIR/bitbeast" "$BIN_DIR/bitbeast-battery" "$BIN_DIR/bitbeast-media" "$BIN_DIR/bitbeast-session" "$BIN_DIR/bitbeast-wallpaper-selector" "$BIN_DIR/circular_cava.py"

if [ "$APPLY_RUNTIME" -eq 1 ]; then
    "$BIN_DIR/bitbeast" "$THEME_NAME"
else
    BITBEAST_SKIP_RUNTIME=1 "$BIN_DIR/bitbeast" "$THEME_NAME"
fi

printf '\nInstalled BitBeast to %s\n' "$CONFIG_HOME"
printf 'Default theme: %s\n' "$THEME_NAME"
printf 'Default Waybar style: %s\n' "$(sed -n '1p' "$STATE_DIR/current.style")"
printf 'Wallpapers: %s\n' "$WALLPAPER_DEST_DIR"
printf 'CLI: %s\n' "$BIN_DIR/bitbeast"

if [ "$BACKUPS_CREATED" -eq 1 ]; then
    printf 'Backups: %s\n' "$BACKUP_ROOT"
fi

if [ "$APPLY_RUNTIME" -eq 0 ]; then
    printf 'Run `bitbeast %s` after login if you want to reload the live session immediately.\n' "$THEME_NAME"
fi

case ":$PATH:" in
    *":$BIN_DIR:"*) ;;
    *) printf 'Add %s to your PATH if `bitbeast` is not found in new shells.\n' "$BIN_DIR" ;;
esac
