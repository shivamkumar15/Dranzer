import re

with open("install.sh", "r") as f:
    content = f.read()

old_func = """    pkg_name() {
        key=$1
        case "$PKG_MANAGER:$key" in
            pacman:hyprland|apt:hyprland|dnf:hyprland) printf 'hyprland' ;;
            pacman:waybar|apt:waybar|dnf:waybar) printf 'waybar' ;;
            pacman:rofi|apt:rofi|dnf:rofi) printf 'rofi' ;;
            pacman:kitty|apt:kitty|dnf:kitty) printf 'kitty' ;;
            pacman:hyprlock|apt:hyprlock|dnf:hyprlock) printf 'hyprlock' ;;
            pacman:swaync|apt:swaync|dnf:swaync) printf 'swaync' ;;
            pacman:playerctl|apt:playerctl|dnf:playerctl) printf 'playerctl' ;;
            pacman:cava|apt:cava|dnf:cava) printf 'cava' ;;
            pacman:pipewire|apt:pipewire|dnf:pipewire) printf 'pipewire' ;;
            pacman:wireplumber|apt:wireplumber|dnf:wireplumber) printf 'wireplumber' ;;
            pacman:xdg-desktop-portal-hyprland|apt:xdg-desktop-portal-hyprland|dnf:xdg-desktop-portal-hyprland) printf 'xdg-desktop-portal-hyprland' ;;
            pacman:fastfetch|apt:fastfetch|dnf:fastfetch) printf 'fastfetch' ;;
            pacman:cliphist|apt:cliphist|dnf:cliphist) printf 'cliphist' ;;
            pacman:git|apt:git|dnf:git) printf 'git' ;;
            pacman:bash|apt:bash|dnf:bash) printf 'bash' ;;
            pacman:swww|apt:swww|dnf:swww) printf 'swww' ;;
            pacman:swaybg|apt:swaybg|dnf:swaybg) printf 'swaybg' ;;
            pacman:awww|apt:awww|dnf:awww) printf 'awww' ;;
            pacman:brightnessctl|apt:brightnessctl|dnf:brightnessctl) printf 'brightnessctl' ;;
            pacman:light|apt:light|dnf:light) printf 'light' ;;
            pacman:grim|apt:grim|dnf:grim) printf 'grim' ;;
            pacman:slurp|apt:slurp|dnf:slurp) printf 'slurp' ;;
            pacman:wl-copy) printf 'wl-clipboard' ;;
            apt:wl-copy|dnf:wl-copy) printf 'wl-clipboard' ;;
            pacman:pavucontrol|apt:pavucontrol|dnf:pavucontrol) printf 'pavucontrol' ;;
            pacman:network-manager-applet|apt:network-manager-applet|dnf:network-manager-applet) printf 'network-manager-applet' ;;
            pacman:blueman|apt:blueman|dnf:blueman) printf 'blueman' ;;
            pacman:jetbrainsmono-nerd) printf 'ttf-jetbrains-mono-nerd' ;;
            apt:jetbrainsmono-nerd) printf 'fonts-jetbrains-mono' ;;
            dnf:jetbrainsmono-nerd) printf 'jetbrains-mono-fonts' ;;
            *) printf '' ;;
        esac
    }"""

new_func = """    pkg_name() {
        key=$1
        case "$PKG_MANAGER:$key" in
            pacman:hyprland|yay:hyprland|paru:hyprland|apt:hyprland|dnf:hyprland) printf 'hyprland' ;;
            pacman:waybar|yay:waybar|paru:waybar|apt:waybar|dnf:waybar) printf 'waybar' ;;
            pacman:rofi|yay:rofi|paru:rofi) printf 'rofi-wayland' ;;
            apt:rofi|dnf:rofi) printf 'rofi' ;;
            pacman:kitty|yay:kitty|paru:kitty|apt:kitty|dnf:kitty) printf 'kitty' ;;
            pacman:hyprlock|yay:hyprlock|paru:hyprlock|apt:hyprlock|dnf:hyprlock) printf 'hyprlock' ;;
            pacman:swaync|yay:swaync|paru:swaync|apt:swaync|dnf:swaync) printf 'swaync' ;;
            pacman:playerctl|yay:playerctl|paru:playerctl|apt:playerctl|dnf:playerctl) printf 'playerctl' ;;
            pacman:cava|yay:cava|paru:cava|apt:cava|dnf:cava) printf 'cava' ;;
            pacman:pipewire|yay:pipewire|paru:pipewire|apt:pipewire|dnf:pipewire) printf 'pipewire' ;;
            pacman:wireplumber|yay:wireplumber|paru:wireplumber|apt:wireplumber|dnf:wireplumber) printf 'wireplumber' ;;
            pacman:xdg-desktop-portal-hyprland|yay:xdg-desktop-portal-hyprland|paru:xdg-desktop-portal-hyprland|apt:xdg-desktop-portal-hyprland|dnf:xdg-desktop-portal-hyprland) printf 'xdg-desktop-portal-hyprland' ;;
            pacman:fastfetch|yay:fastfetch|paru:fastfetch|apt:fastfetch|dnf:fastfetch) printf 'fastfetch' ;;
            pacman:cliphist|yay:cliphist|paru:cliphist|apt:cliphist|dnf:cliphist) printf 'cliphist' ;;
            pacman:git|yay:git|paru:git|apt:git|dnf:git) printf 'git' ;;
            pacman:bash|yay:bash|paru:bash|apt:bash|dnf:bash) printf 'bash' ;;
            pacman:swww|yay:swww|paru:swww|apt:swww|dnf:swww) printf 'swww' ;;
            pacman:swaybg|yay:swaybg|paru:swaybg|apt:swaybg|dnf:swaybg) printf 'swaybg' ;;
            pacman:awww|yay:awww|paru:awww|apt:awww|dnf:awww) printf 'awww' ;;
            pacman:brightnessctl|yay:brightnessctl|paru:brightnessctl|apt:brightnessctl|dnf:brightnessctl) printf 'brightnessctl' ;;
            pacman:light|yay:light|paru:light|apt:light|dnf:light) printf 'light' ;;
            pacman:grim|yay:grim|paru:grim|apt:grim|dnf:grim) printf 'grim' ;;
            pacman:slurp|yay:slurp|paru:slurp|apt:slurp|dnf:slurp) printf 'slurp' ;;
            pacman:wl-copy|yay:wl-copy|paru:wl-copy|apt:wl-copy|dnf:wl-copy) printf 'wl-clipboard' ;;
            pacman:pavucontrol|yay:pavucontrol|paru:pavucontrol|apt:pavucontrol|dnf:pavucontrol) printf 'pavucontrol' ;;
            pacman:network-manager-applet|yay:network-manager-applet|paru:network-manager-applet|apt:network-manager-applet|dnf:network-manager-applet) printf 'network-manager-applet' ;;
            pacman:blueman|yay:blueman|paru:blueman|apt:blueman|dnf:blueman) printf 'blueman' ;;
            pacman:jetbrainsmono-nerd|yay:jetbrainsmono-nerd|paru:jetbrainsmono-nerd) printf 'ttf-jetbrains-mono-nerd' ;;
            apt:jetbrainsmono-nerd) printf 'fonts-jetbrains-mono' ;;
            dnf:jetbrainsmono-nerd) printf 'jetbrains-mono-fonts' ;;
            *) printf '' ;;
        esac
    }"""

if old_func in content:
    content = content.replace(old_func, new_func)
    with open("install.sh", "w") as f:
        f.write(content)
    print("Replaced successfully")
else:
    print("Not found")

