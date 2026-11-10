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
SKIP_DEPS=0
SKIP_SYSTEM=0
SKIP_HYPRSPACE=0
SKIP_ZSH=0
PKG_MANAGER=""
TOUCHPAD_NAME=""
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

info() {
    printf '\033[1;36m%s\033[0m\n' "$*"
}

warn() {
    printf '\033[1;33mWarning: %s\033[0m\n' "$*" >&2
}

have() {
    command -v "$1" >/dev/null 2>&1
}

run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    elif have sudo; then
        sudo "$@"
    else
        return 1
    fi
}

detect_package_manager() {
    if have yay; then
        PKG_MANAGER="yay"
    elif have paru; then
        PKG_MANAGER="paru"
    elif have pacman; then
        PKG_MANAGER="pacman"
        warn "No AUR helper (yay/paru) detected; using pacman for official packages."
    elif have apt-get; then
        PKG_MANAGER="apt"
    elif have dnf; then
        PKG_MANAGER="dnf"
    else
        PKG_MANAGER=""
    fi
}

# Translate a dependency key to a package name for the detected package manager.
# Returns an empty string when the dependency has no reliable package mapping
# and must be installed manually.
pkg_name() {
    key=$1

    [ -n "$PKG_MANAGER" ] || {
        printf ''
        return
    }

    case "$PKG_MANAGER" in
        pacman|yay|paru)
            case "$key" in
                rofi) printf 'rofi-wayland' ;;
                python3) printf 'python' ;;
                wl-copy) printf 'wl-clipboard' ;;
                notify-send) printf 'libnotify' ;;
                xdg-open) printf 'xdg-utils' ;;
                pactl) printf 'pipewire-pulse' ;;
                bluetoothctl) printf 'bluez-utils' ;;
                g++) printf 'gcc' ;;
                pkg-config) printf 'pkgconf' ;;
                jetbrainsmono-nerd) printf 'ttf-jetbrains-mono-nerd' ;;
                imagemagick) printf 'imagemagick' ;;
                webkit2gtk) printf 'webkit2gtk-4.1' ;;
                *) printf '%s' "$key" ;;
            esac
            ;;
        apt)
            case "$key" in
                swaync) printf 'sway-notification-center' ;;
                python-gobject) printf 'python3-gi' ;;
                gtk-layer-shell) printf 'gir1.2-gtklayershell-0.1' ;;
                gtk3) printf 'gir1.2-gtk-3.0' ;;
                wl-copy) printf 'wl-clipboard' ;;
                pactl) printf 'pipewire-pulse' ;;
                bluetoothctl) printf 'bluez' ;;
                g++) printf 'g++' ;;
                webkit2gtk)
                    if apt-cache show gir1.2-webkit2-4.1 >/dev/null 2>&1; then
                        printf 'gir1.2-webkit2-4.1'
                    elif apt-cache show gir1.2-webkit2-4.0 >/dev/null 2>&1; then
                        printf 'gir1.2-webkit2-4.0'
                    else
                        printf 'gir1.2-webkit2-4.1'
                    fi
                    ;;
                networkmanager) printf 'network-manager' ;;
                network-manager-applet) printf 'network-manager-gnome' ;;
                notify-send) printf 'libnotify-bin' ;;
                xdg-open) printf 'xdg-utils' ;;
                libnotify) printf 'libnotify-bin' ;;
                pkg-config) printf 'pkg-config' ;;
                jetbrainsmono-nerd) printf '' ;;
                *) printf '%s' "$key" ;;
            esac
            ;;
        dnf)
            case "$key" in
                python-gobject) printf 'python3-gobject' ;;
                wl-copy) printf 'wl-clipboard' ;;
                pactl) printf 'pipewire-pulseaudio' ;;
                bluetoothctl) printf 'bluez' ;;
                g++) printf 'gcc-c++' ;;
                pkg-config) printf 'pkgconf' ;;
                networkmanager) printf 'NetworkManager' ;;
                notify-send) printf 'libnotify' ;;
                xdg-open) printf 'xdg-utils' ;;
                imagemagick) printf 'ImageMagick' ;;
                jetbrainsmono-nerd) printf '' ;;
                webkit2gtk) printf 'webkit2gtk4.1' ;;
                *) printf '%s' "$key" ;;
            esac
            ;;
    esac
}

run_pkg_install() {
    [ -n "$PKG_MANAGER" ] || return 1

    case "$PKG_MANAGER" in
        yay) yay -S --needed --noconfirm "$@" ;;
        paru) paru -S --needed --noconfirm "$@" ;;
        pacman) run_privileged pacman -S --needed --noconfirm "$@" ;;
        apt) run_privileged apt-get install -y "$@" ;;
        dnf) run_privileged dnf install -y "$@" ;;
        *) return 1 ;;
    esac
}

install_packages() {
    kind=$1
    shift

    [ $# -gt 0 ] || return 0

    local uniq_pkgs=()
    mapfile -t uniq_pkgs < <(printf '%s\n' "$@" | awk 'NF && !seen[$0]++')

    [ ${#uniq_pkgs[@]} -gt 0 ] || return 0

    info "Installing $kind packages: ${uniq_pkgs[*]}"
    if run_pkg_install "${uniq_pkgs[@]}"; then
        return 0
    fi

    warn "Batch installation failed; retrying packages one at a time so one bad name cannot block the rest."
    local failed=()
    for pkg in "${uniq_pkgs[@]}"; do
        if ! run_pkg_install "$pkg"; then
            failed+=("$pkg")
        fi
    done

    if [ ${#failed[@]} -gt 0 ]; then
        printf '\033[1;31mCould not install %s package(s):\033[0m %s\n' "$kind" "${failed[*]}" >&2
        return 1
    fi
}

find_browser_cmd() {
    if [ -n "${BITBEAST_BROWSER:-}" ] && have "$BITBEAST_BROWSER"; then
        printf '%s\n' "$BITBEAST_BROWSER"
        return 0
    fi

    for cmd in google-chrome-stable google-chrome chromium chromium-browser \
        brave-browser brave microsoft-edge microsoft-edge-stable \
        vivaldi vivaldi-stable firefox firefox-esr; do
        if have "$cmd"; then
            printf '%s\n' "$cmd"
            return 0
        fi
    done

    return 1
}

check_dependencies() {
    detect_package_manager

    local required_pkgs=()
    local optional_pkgs=()
    local required_labels=()
    local optional_labels=()

    add_required() {
        key=$1
        label=${2:-$1}
        pkg=$(pkg_name "$key")
        if [ -n "$pkg" ]; then
            required_pkgs+=("$pkg")
        else
            required_labels+=("$label")
        fi
    }

    add_optional() {
        key=$1
        label=${2:-$1}
        pkg=$(pkg_name "$key")
        if [ -n "$pkg" ]; then
            optional_pkgs+=("$pkg")
        else
            optional_labels+=("$label")
        fi
    }

    if ! have Hyprland && ! have hyprland; then
        add_required "hyprland" "Hyprland"
    fi

    for cmd in waybar rofi kitty hyprlock swaync playerctl cava \
        pipewire wireplumber pactl git bash python3 jq bc \
        notify-send zsh swaybg xdg-open grim slurp wl-copy cliphist; do
        if ! have "$cmd"; then
            add_required "$cmd" "$cmd"
        fi
    done

    if ! python3 -c "import gi" >/dev/null 2>&1; then
        add_required "python-gobject" "python-gobject (PyGObject)"
    fi

    if ! python3 -c "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk" >/dev/null 2>&1; then
        add_required "gtk3" "GTK 3 (Gtk-3.0 typelib)"
    fi

    if ! python3 -c "import gi; gi.require_version('GtkLayerShell', '0.1'); from gi.repository import GtkLayerShell" >/dev/null 2>&1; then
        add_required "gtk-layer-shell" "gtk-layer-shell"
    fi

    if ! python3 - <<'PY' >/dev/null 2>&1
import gi
try:
    gi.require_version("WebKit2", "4.1")
except ValueError:
    gi.require_version("WebKit2", "4.0")
from gi.repository import WebKit2  # noqa: F401
PY
    then
        add_required "webkit2gtk" "WebKit2GTK 4.1 or 4.0 (wallpaper picker)"
    fi

    if ! have xdg-desktop-portal-hyprland \
        && [ ! -x /usr/lib/xdg-desktop-portal-hyprland ] \
        && [ ! -x /usr/libexec/xdg-desktop-portal-hyprland ]; then
        add_required "xdg-desktop-portal-hyprland" "xdg-desktop-portal-hyprland"
    fi

    if [ "$SKIP_HYPRSPACE" -eq 0 ]; then
        for cmd in make gcc g++ pkg-config; do
            if ! have "$cmd"; then
                add_required "$cmd" "$cmd"
            fi
        done

        if have pkg-config && ! pkg-config --exists hyprland; then
            required_labels+=("Hyprland development headers (pkg-config hyprland)")
        fi
    fi

    if ! have fastfetch; then
        add_optional "fastfetch" "fastfetch"
    fi

    if ! find_browser_cmd >/dev/null 2>&1; then
        add_optional "firefox" "Firefox (fallback web browser)"
    fi

    if ! have curl; then
        add_optional "curl" "curl"
    fi

    if ! have brightnessctl && ! have light; then
        add_required "brightnessctl" "brightnessctl"
    fi

    if ! have convert && ! have magick; then
        add_optional "imagemagick" "ImageMagick (wallpaper theme detection)"
    fi

    if ! have powerprofilesctl; then
        add_optional "power-profiles-daemon" "power-profiles-daemon"
    fi

    for cmd in pavucontrol nm-applet nm-connection-editor blueman-manager; do
        if ! have "$cmd"; then
            case "$cmd" in
                nm-applet) add_optional "network-manager-applet" "network-manager-applet" ;;
                nm-connection-editor) add_optional "network-manager-applet" "NetworkManager connection editor" ;;
                blueman-manager) add_optional "blueman" "blueman" ;;
                *) add_optional "$cmd" "$cmd" ;;
            esac
        fi
    done

    if ! have nmcli; then
        add_optional "networkmanager" "NetworkManager (nmcli)"
    fi

    if ! have bluetoothctl; then
        add_optional "bluez" "BlueZ"
        add_optional "bluetoothctl" "BlueZ utilities (bluetoothctl)"
    fi

    if ! have dolphin; then
        add_optional "dolphin" "Dolphin file manager"
    fi

    if ! have yazi; then
        add_optional "yazi" "yazi terminal file manager"
    fi

    if have fc-list; then
        if ! fc-list | grep -qi 'jetbrainsmono nerd'; then
            add_optional "jetbrainsmono-nerd" "JetBrainsMono Nerd Font"
        fi
    else
        add_optional "jetbrainsmono-nerd" "JetBrainsMono Nerd Font"
    fi

    if [ ${#required_pkgs[@]} -eq 0 ] && [ ${#optional_pkgs[@]} -eq 0 ] \
        && [ ${#required_labels[@]} -eq 0 ] && [ ${#optional_labels[@]} -eq 0 ]; then
        info "All dependencies are already installed."
        return 0
    fi

    printf '\n'
    info "=== Dependency Check ==="
    if [ ${#required_pkgs[@]} -gt 0 ]; then
        printf '\033[1;31mMissing required packages:\033[0m %s\n' "${required_pkgs[*]}"
    fi
    if [ ${#required_labels[@]} -gt 0 ]; then
        printf '\033[1;31mRequired, install manually:\033[0m %s\n' "${required_labels[*]}"
    fi
    if [ ${#optional_pkgs[@]} -gt 0 ]; then
        printf '\033[1;33mRecommended packages:\033[0m %s\n' "${optional_pkgs[*]}"
    fi
    if [ ${#optional_labels[@]} -gt 0 ]; then
        printf '\033[1;33mRecommended, install manually:\033[0m %s\n' "${optional_labels[*]}"
    fi

    if [ -z "$PKG_MANAGER" ]; then
        if [ ${#required_pkgs[@]} -gt 0 ] || [ ${#required_labels[@]} -gt 0 ]; then
            printf '\nNo supported package manager found. Install the required packages above and rerun the installer.\n' >&2
            exit 1
        fi
        warn "No supported package manager found. Install recommended packages manually if needed."
        return 0
    fi

    if [ "$PKG_MANAGER" = "apt" ] \
        && { [ ${#required_pkgs[@]} -gt 0 ] || [ ${#optional_pkgs[@]} -gt 0 ]; }; then
        run_privileged apt-get update || warn "apt-get update failed; continuing with the existing package lists."
    fi

    local required_failed=0
    if [ ${#required_pkgs[@]} -gt 0 ]; then
        install_packages "required" "${required_pkgs[@]}" || required_failed=1
    fi

    if [ ${#optional_pkgs[@]} -gt 0 ]; then
        install_packages "optional" "${optional_pkgs[@]}" || warn "Some optional packages could not be installed; continuing."
    fi

    # Package names differ between distributions. Verify the actual commands and
    # Python bindings instead of trusting a successful package-manager exit code.
    local missing=()
    if ! have Hyprland && ! have hyprland; then
        missing+=("Hyprland")
    fi
    for cmd in waybar rofi kitty hyprlock swaync playerctl cava \
        pipewire wireplumber pactl git bash python3 jq bc \
        notify-send zsh swaybg xdg-open grim slurp wl-copy cliphist; do
        have "$cmd" || missing+=("$cmd")
    done
    python3 -c "import gi" >/dev/null 2>&1 || missing+=("python-gobject")
    python3 -c "import gi; gi.require_version('Gtk', '3.0'); from gi.repository import Gtk" >/dev/null 2>&1 || missing+=("GTK 3")
    python3 -c "import gi; gi.require_version('GtkLayerShell', '0.1'); from gi.repository import GtkLayerShell" >/dev/null 2>&1 || missing+=("gtk-layer-shell")
    python3 - <<'PY' >/dev/null 2>&1 || missing+=("WebKit2GTK 4.1/4.0")
import gi
try:
    gi.require_version("WebKit2", "4.1")
except ValueError:
    gi.require_version("WebKit2", "4.0")
from gi.repository import WebKit2  # noqa: F401
PY

    if ! have brightnessctl && ! have light; then
        missing+=("brightnessctl")
    fi

    if ! have xdg-desktop-portal-hyprland \
        && [ ! -x /usr/lib/xdg-desktop-portal-hyprland ] \
        && [ ! -x /usr/libexec/xdg-desktop-portal-hyprland ]; then
        missing+=("xdg-desktop-portal-hyprland")
    fi

    if [ "$SKIP_HYPRSPACE" -eq 0 ]; then
        for cmd in make gcc g++ pkg-config; do
            have "$cmd" || missing+=("$cmd")
        done
        if have pkg-config && ! pkg-config --exists hyprland; then
            missing+=("Hyprland development headers")
        fi
    fi

    if [ ${#missing[@]} -gt 0 ] || [ "$required_failed" -eq 1 ]; then
        printf '\n\033[1;31mRequired dependencies are still missing:\033[0m %s\n' "${missing[*]}" >&2
        if [ ${#required_labels[@]} -gt 0 ]; then
            printf 'Also install manually: %s\n' "${required_labels[*]}" >&2
        fi
        printf 'Install them and rerun ./install.sh (or use --no-deps to skip this check).\n' >&2
        exit 1
    fi

    info "Dependency check passed."
}

usage() {
    cat <<EOF
Usage: ./install.sh [options]

Options:
  --theme <name>    Install and activate a specific BitBeast theme.
  --apply           Reload live desktop components after install.
  --force           Overwrite existing files without creating backups.
  --no-deps         Skip dependency checks and automatic package installation.
  --skip-system     Do not enable services or install the touchpad udev rule.
  --skip-hyprspace  Do not download/build the Hyprspace plugin.
  --skip-zsh        Do not install or configure Oh My Zsh.
  -h, --help        Show this help message.
EOF
}

ensure_theme_exists() {
    theme_dir=$1
    if [ ! -d "$THEMES_SRC_DIR/$theme_dir" ]; then
        printf 'Unknown BitBeast theme: %s\n' "$theme_dir" >&2
        exit 1
    fi
}

backup_relative_path() {
    target_path=$1

    case "$target_path" in
        "$HOME"/*) printf '%s\n' "${target_path#"$HOME"/}" ;;
        "$CONFIG_HOME"/*) printf 'config/%s\n' "${target_path#"$CONFIG_HOME"/}" ;;
        "$DATA_HOME"/*) printf 'data/%s\n' "${target_path#"$DATA_HOME"/}" ;;
        "$STATE_HOME"/*) printf 'state/%s\n' "${target_path#"$STATE_HOME"/}" ;;
        *) printf '%s\n' "${target_path#/}" ;;
    esac
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

    relative_path=$(backup_relative_path "$target_path")
    backup_target="$BACKUP_ROOT/$relative_path"
    mkdir -p "$(dirname "$backup_target")"
    mv "$target_path" "$backup_target"
    BACKUPS_CREATED=1
}

backup_copy_path() {
    target_path=$1

    if [ ! -e "$target_path" ] && [ ! -L "$target_path" ]; then
        return
    fi

    relative_path=$(backup_relative_path "$target_path")
    backup_target="$BACKUP_ROOT/$relative_path"
    mkdir -p "$(dirname "$backup_target")"
    cp -a "$target_path" "$backup_target"
    BACKUPS_CREATED=1
}

install_file() {
    source_path=$1
    target_path=$2

    if [ ! -f "$source_path" ]; then
        return
    fi

    if [ -f "$target_path" ] && cmp -s "$source_path" "$target_path"; then
        return
    fi

    backup_path "$target_path"
    mkdir -p "$(dirname "$target_path")"
    cp "$source_path" "$target_path"
}

install_dir() {
    source_path=$1
    target_path=$2

    if [ ! -d "$source_path" ]; then
        return
    fi

    if [ -d "$target_path" ] && diff -qr "$source_path" "$target_path" >/dev/null 2>&1; then
        return
    fi

    if [ -d "$target_path" ] || [ -e "$target_path" ] || [ -L "$target_path" ]; then
        backup_path "$target_path"
    fi

    mkdir -p "$(dirname "$target_path")"
    cp -R "$source_path" "$target_path"
}

detect_touchpad_name() {
    for name_file in /sys/class/input/event*/device/name; do
        [ -r "$name_file" ] || continue
        name=$(cat "$name_file" 2>/dev/null) || continue
        lower_name=$(printf '%s' "$name" | tr '[:upper:]' '[:lower:]')
        case "$lower_name" in
            *touchpad*)
                printf '%s\n' "$name"
                return 0
                ;;
        esac
    done
    return 1
}

setup_touchpad_config() {
    TOUCHPAD_NAME=$(detect_touchpad_name || true)
    touchpad_conf="$CONFIG_HOME/hypr/touchpad.conf"

    if [ -z "$TOUCHPAD_NAME" ]; then
        printf 'No touchpad detected; keeping the existing touchpad configuration.\n'
        if [ ! -f "$touchpad_conf" ]; then
            mkdir -p "$(dirname "$touchpad_conf")"
            cp "$REPO_DIR/.config/hypr/touchpad.conf" "$touchpad_conf"
        fi
        return 0
    fi

    existing_name=$(sed -n 's/^[[:space:]]*name[[:space:]]*=[[:space:]]*//p' "$touchpad_conf" 2>/dev/null | tail -n 1)

    case "$existing_name" in
        ""|elan0001*)
            if [ -f "$touchpad_conf" ]; then
                backup_path "$touchpad_conf"
            fi
            mkdir -p "$(dirname "$touchpad_conf")"
            cat > "$touchpad_conf" <<EOF
device {
    name = $TOUCHPAD_NAME
    sensitivity = 0
}
EOF
            printf 'Detected touchpad: %s\n' "$TOUCHPAD_NAME"
            ;;
        *)
            printf 'Keeping existing touchpad configuration for: %s\n' "$existing_name"
            ;;
    esac
}

setup_touchpad_udev() {
    [ "$SKIP_SYSTEM" -eq 0 ] || return 0
    [ -n "$TOUCHPAD_NAME" ] || return 0
    have udevadm || return 0

    rule_path="/etc/udev/rules.d/99-bitbeast-touchpad.rules"
    rule='# BitBeast - allow the seat user to read the touchpad for volume gestures
KERNEL=="event*", ENV{ID_INPUT_TOUCHPAD}=="1", TAG+="uaccess"'

    if printf '%s\n' "$rule" | run_privileged tee "$rule_path" >/dev/null 2>&1; then
        run_privileged udevadm control --reload-rules >/dev/null 2>&1 || true
        run_privileged udevadm trigger --subsystem-match=input --action=change >/dev/null 2>&1 || true
        info "Touchpad udev rule installed."
    else
        warn "Could not install the touchpad udev rule (administrator access unavailable)."
    fi
}

setup_services() {
    [ "$SKIP_SYSTEM" -eq 0 ] || return 0
    have systemctl || return 0

    for service in NetworkManager bluetooth power-profiles-daemon; do
        if systemctl list-unit-files "$service.service" 2>/dev/null | grep -q "^$service\.service"; then
            if run_privileged systemctl enable --now "$service.service" >/dev/null 2>&1; then
                printf 'Enabled service: %s\n' "$service"
            else
                warn "Could not enable $service.service"
            fi
        fi
    done
}

setup_path() {
    for rc_file in "$HOME/.profile" "$HOME/.bashrc" "$HOME/.bash_profile"; do
        [ -e "$rc_file" ] || continue
        if ! grep -q 'BitBeast PATH' "$rc_file" 2>/dev/null; then
            backup_copy_path "$rc_file"
            cat >> "$rc_file" <<'EOF'

# BitBeast PATH
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
EOF
        fi
    done

    if [ ! -e "$HOME/.profile" ] && [ ! -e "$HOME/.bash_profile" ]; then
        cat > "$HOME/.profile" <<'EOF'
# BitBeast PATH
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
EOF
    fi
}

install_omz_plugin() {
    plugin=$1
    plugin_dir="$ZSH_DIR/plugins/$plugin"

    if [ ! -d "$plugin_dir" ]; then
        mkdir -p "$ZSH_DIR/plugins"
        printf 'Installing zsh plugin: %s...\n' "$plugin"
        git clone --depth 1 "https://github.com/zsh-users/$plugin.git" "$plugin_dir" \
            || warn "Could not install zsh plugin: $plugin"
    elif [ -d "$plugin_dir/.git" ]; then
        git -C "$plugin_dir" pull --ff-only >/dev/null 2>&1 \
            || warn "Could not update zsh plugin: $plugin"
    fi
}

set_default_shell() {
    zsh_path=$(command -v zsh 2>/dev/null || true)
    [ -n "$zsh_path" ] || return 0

    current_user=$(id -un)
    passwd_entry=$(getent passwd "$current_user" 2>/dev/null || true)
    [ -n "$passwd_entry" ] || return 0

    real_home=$(printf '%s\n' "$passwd_entry" | cut -d: -f6)
    current_shell=$(printf '%s\n' "$passwd_entry" | cut -d: -f7)

    # Do not change the login shell when testing with a temporary HOME.
    [ "$real_home" = "$HOME" ] || return 0
    [ "$current_shell" != "$zsh_path" ] || return 0

    if run_privileged chsh -s "$zsh_path" "$current_user" >/dev/null 2>&1; then
        printf 'Default shell set to %s (takes effect after the next login).\n' "$zsh_path"
    else
        warn "Could not change the default shell. Run: chsh -s $zsh_path"
    fi
}

setup_zsh() {
    [ "$SKIP_ZSH" -eq 0 ] || {
        printf 'Skipping zsh setup (--skip-zsh).\n'
        return 0
    }

    ZSH_DIR="$HOME/.oh-my-zsh"
    ZSHRC="$HOME/.zshrc"
    ZSH_HISTORY_FILE="$HOME/.zsh_history"

    info "=== Zsh Setup ==="

    if [ ! -d "$ZSH_DIR" ]; then
        printf 'Installing Oh My Zsh...\n'
        if ! git clone --depth 1 https://github.com/ohmyzsh/ohmyzsh.git "$ZSH_DIR"; then
            warn "Could not clone Oh My Zsh. A .zshrc will still be written; rerun the installer after fixing network access."
        fi
    fi

    if [ -d "$ZSH_DIR" ]; then
        mkdir -p "$ZSH_DIR/plugins" "$ZSH_DIR/themes" "$ZSH_DIR/custom/themes"
        install_file "$REPO_DIR/.oh-my-zsh/themes/bitbeast.zsh-theme" "$ZSH_DIR/custom/themes/bitbeast.zsh-theme"
        install_omz_plugin "zsh-autosuggestions"
        install_omz_plugin "zsh-syntax-highlighting"
    fi

    if [ -f "$ZSH_HISTORY_FILE" ] && python3 - "$ZSH_HISTORY_FILE" <<'PY'
import sys

with open(sys.argv[1], "rb") as history:
    raise SystemExit(0 if b"\0" in history.read() else 1)
PY
    then
        if have strings; then
            printf 'Detected corrupted zsh history. Recovering printable entries...\n'
            cp "$ZSH_HISTORY_FILE" "$ZSH_HISTORY_FILE.corrupt.$(date +%Y%m%d-%H%M%S)"
            strings "$ZSH_HISTORY_FILE" > "$ZSH_HISTORY_FILE.recovered"
            mv "$ZSH_HISTORY_FILE.recovered" "$ZSH_HISTORY_FILE"
        else
            warn "Corrupted zsh history detected, but 'strings' is unavailable; leaving the file untouched."
        fi
    fi

    if [ ! -e "$ZSH_HISTORY_FILE" ]; then
        touch "$ZSH_HISTORY_FILE"
    fi
    chmod 600 "$ZSH_HISTORY_FILE" 2>/dev/null || true

    if [ -f "$ZSHRC" ]; then
        backup_path "$ZSHRC"
    fi

    cat > "$ZSHRC" <<'EOF'
# BitBeast zsh configuration
export PATH="$HOME/.local/bin:$PATH"

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="bitbeast"

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

if [ -d "$ZSH" ]; then
    source "$ZSH/oh-my-zsh.sh"
fi

HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000

setopt INC_APPEND_HISTORY
setopt HIST_FCNTL_LOCK
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt HIST_REDUCE_BLANKS
unsetopt SHARE_HISTORY

[[ -f "$HISTFILE" ]] || touch "$HISTFILE"
chmod 600 "$HISTFILE" 2>/dev/null || true

[[ -f "$HOME/.zsh/bitbeast-prompt.zsh" ]] && source "$HOME/.zsh/bitbeast-prompt.zsh"
EOF

    set_default_shell
    printf 'Zsh configured with the BitBeast theme.\n'
}

setup_hyprspace() {
    if [ "$SKIP_HYPRSPACE" -eq 1 ]; then
        printf 'Skipping Hyprspace build (--skip-hyprspace).\n'
        return 0
    fi

    if [ ! -x "$BIN_DIR/bitbeast-hyprspace" ]; then
        return 0
    fi

    info "=== Hyprspace Plugin ==="
    if "$BIN_DIR/bitbeast-hyprspace" build; then
        info "Hyprspace built and installed."
    else
        warn "Hyprspace could not be built. The desktop will still work, but the workspace overview will be unavailable."
    fi
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
        --no-deps)
            SKIP_DEPS=1
            shift
            ;;
        --skip-system)
            SKIP_SYSTEM=1
            shift
            ;;
        --skip-hyprspace)
            SKIP_HYPRSPACE=1
            shift
            ;;
        --skip-zsh)
            SKIP_ZSH=1
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

ensure_theme_exists "$THEME_NAME"

if [ "$SKIP_DEPS" -eq 1 ]; then
    printf '\033[1;33mSkipping dependency checks (--no-deps).\033[0m\n'
else
    check_dependencies
fi

setup_zsh
setup_path
setup_services

mkdir -p "$BIN_DIR" "$STATE_DIR" "$WALLPAPER_DEST_DIR"

install_dir "$THEMES_SRC_DIR" "$THEMES_DEST_DIR"
install_dir "$REPO_DIR/.config/waybar/styles" "$CONFIG_HOME/waybar/styles"
install_dir "$REPO_DIR/.config/waybar/layouts" "$CONFIG_HOME/waybar/layouts"

for wallpaper_name in $WALLPAPER_SRC_FILES; do
    install_file "$REPO_DIR/$wallpaper_name" "$WALLPAPER_DEST_DIR/$wallpaper_name"
done

install_file "$REPO_DIR/.config/bitbeast/current.style" "$STATE_DIR/current.style"
install_file "$REPO_DIR/.config/hypr/hyprland.conf" "$CONFIG_HOME/hypr/hyprland.conf"
install_file "$REPO_DIR/.config/hypr/hyprland.lua" "$CONFIG_HOME/hypr/hyprland.lua"
install_file "$REPO_DIR/.config/hypr/hyprlock.conf" "$CONFIG_HOME/hypr/hyprlock.conf"
setup_touchpad_config
install_dir "$REPO_DIR/.config/waybar/modules" "$CONFIG_HOME/waybar/modules"
install_dir "$REPO_DIR/.config/waybar/includes" "$CONFIG_HOME/waybar/includes"
install_file "$REPO_DIR/.config/waybar/theme.css" "$CONFIG_HOME/waybar/theme.css"

install_file "$REPO_DIR/.config/waybar/style.css" "$CONFIG_HOME/waybar/style.css"
install_file "$REPO_DIR/.config/waybar/bitbeast-style.css" "$CONFIG_HOME/waybar/bitbeast-style.css"
# Base module definitions + live config (layout merge writes config.jsonc on style switch)
install_file "$REPO_DIR/.config/waybar/config.jsonc" "$CONFIG_HOME/waybar/config.base.jsonc"
install_file "$REPO_DIR/.config/waybar/config.jsonc" "$CONFIG_HOME/waybar/config.jsonc"
install_file "$REPO_DIR/.config/kitty/kitty.conf" "$CONFIG_HOME/kitty/kitty.conf"
install_dir "$REPO_DIR/.config/kitty/themes" "$CONFIG_HOME/kitty/themes"
install_file "$REPO_DIR/.config/rofi/config.rasi" "$CONFIG_HOME/rofi/config.rasi"
install_file "$REPO_DIR/.config/rofi/bitbeast.rasi" "$CONFIG_HOME/rofi/bitbeast.rasi"
install_file "$REPO_DIR/.config/rofi/overview.rasi" "$CONFIG_HOME/rofi/overview.rasi"
install_dir "$REPO_DIR/.config/swaync" "$CONFIG_HOME/swaync"
install_dir "$REPO_DIR/.config/fastfetch" "$CONFIG_HOME/fastfetch"
# Cava profiles: josh (gradient bars) + spiral (rotating Orion ring) and its shaders
install_file "$REPO_DIR/.config/cava/josh.conf" "$CONFIG_HOME/cava/josh.conf"
install_file "$REPO_DIR/.config/cava/spiral.conf" "$CONFIG_HOME/cava/spiral.conf"
install_dir "$REPO_DIR/.config/cava/shaders" "$CONFIG_HOME/cava/shaders"
install_dir "$REPO_DIR/web-wallpaper-selector" "$DATA_HOME/bitbeast/web-wallpaper-selector"
install_file "$REPO_DIR/hyprspace_keyboard_hover.patch" "$DATA_HOME/bitbeast/hyprspace_keyboard_hover.patch"
# Prefer full bitbeast CLI (includes layout-aware style switching)
if [ -f "$REPO_DIR/.local/bin/bitbeast" ]; then
    install_file "$REPO_DIR/.local/bin/bitbeast" "$BIN_DIR/bitbeast"
else
    install_file "$REPO_DIR/.local/bin/bitbeast.sh" "$BIN_DIR/bitbeast"
fi
install_file "$REPO_DIR/.local/bin/bitbeast-battery" "$BIN_DIR/bitbeast-battery"
install_file "$REPO_DIR/.local/bin/bitbeast-battery-saver" "$BIN_DIR/bitbeast-battery-saver"
install_file "$REPO_DIR/.local/bin/bitbeast-battery-watcher" "$BIN_DIR/bitbeast-battery-watcher"
install_file "$REPO_DIR/.local/bin/bitbeast-browser" "$BIN_DIR/bitbeast-browser"
install_file "$REPO_DIR/.local/bin/bitbeast-media" "$BIN_DIR/bitbeast-media"
install_file "$REPO_DIR/.local/bin/bitbeast-media-popup" "$BIN_DIR/bitbeast-media-popup"
install_file "$REPO_DIR/.local/bin/bitbeast-hints-popup" "$BIN_DIR/bitbeast-hints-popup"
install_file "$REPO_DIR/.local/bin/bitbeast-notification" "$BIN_DIR/bitbeast-notification"
install_file "$REPO_DIR/.local/bin/bitbeast-notification-popdown" "$BIN_DIR/bitbeast-notification-popdown"
install_file "$REPO_DIR/.local/bin/bitbeast-osd" "$BIN_DIR/bitbeast-osd"
install_file "$REPO_DIR/.local/bin/bitbeast-control-center" "$BIN_DIR/bitbeast-control-center"
install_file "$REPO_DIR/.local/bin/waybar-mic.sh" "$BIN_DIR/waybar-mic.sh"
install_file "$REPO_DIR/.local/bin/bitbeast-volume-gesture" "$BIN_DIR/bitbeast-volume-gesture"
install_file "$REPO_DIR/.local/bin/bitbeast-session" "$BIN_DIR/bitbeast-session"
install_file "$REPO_DIR/.local/bin/bitbeast-sysinfo" "$BIN_DIR/bitbeast-sysinfo"
install_file "$REPO_DIR/.local/bin/bitbeast-wallpaper-selector" "$BIN_DIR/bitbeast-wallpaper-selector"
install_file "$REPO_DIR/.local/bin/bitbeast_colors.py" "$BIN_DIR/bitbeast_colors.py"
install_file "$REPO_DIR/.local/bin/bitbeast-workspaces" "$BIN_DIR/bitbeast-workspaces"
install_file "$REPO_DIR/.local/bin/bitbeast-workspace-picker" "$BIN_DIR/bitbeast-workspace-picker"
install_file "$REPO_DIR/.local/bin/bitbeast-hyprspace" "$BIN_DIR/bitbeast-hyprspace"
install_file "$REPO_DIR/.local/bin/circular_cava.py" "$BIN_DIR/circular_cava.py"
install_file "$REPO_DIR/.local/bin/toggle-transparency" "$BIN_DIR/toggle-transparency"
install_file "$REPO_DIR/.local/bin/waybar-cava.sh" "$BIN_DIR/waybar-cava.sh"
install_file "$REPO_DIR/.local/bin/waybar-netspeed.sh" "$BIN_DIR/waybar-netspeed.sh"
install_file "$REPO_DIR/.local/bin/waybar-updates.sh" "$BIN_DIR/waybar-updates.sh"
install_file "$REPO_DIR/.local/bin/cava-j" "$BIN_DIR/cava-j"
install_file "$REPO_DIR/.local/bin/cava-spiral" "$BIN_DIR/cava-spiral"
chmod +x "$BIN_DIR"/bitbeast* "$BIN_DIR/circular_cava.py" "$BIN_DIR/toggle-transparency" "$BIN_DIR/waybar-cava.sh" "$BIN_DIR/waybar-netspeed.sh" "$BIN_DIR/waybar-updates.sh" "$BIN_DIR/cava-j" "$BIN_DIR/cava-spiral"

setup_touchpad_udev
setup_hyprspace

if [ "$APPLY_RUNTIME" -eq 1 ]; then
    "$BIN_DIR/bitbeast" "$THEME_NAME"
else
    BITBEAST_SKIP_RUNTIME=1 "$BIN_DIR/bitbeast" "$THEME_NAME"
fi

# Generate the colour-matched zsh prompt used by the BitBeast OMZ theme.
if [ "$SKIP_ZSH" -eq 0 ] && [ -x "$BIN_DIR/bitbeast" ]; then
    "$BIN_DIR/bitbeast" zsh prompt >/dev/null 2>&1 || true
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
    printf 'Log out and select Hyprland. On Hyprland 0.57+, %s/hypr/hyprland.lua is used automatically.\n' "$CONFIG_HOME"
fi
