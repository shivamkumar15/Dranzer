# BitBeast Hyprland Dotfiles

A modular, premium Hyprland theme system inspired by Beyblade BitBeasts.

> [!NOTE]
> Each theme installs into `~/.config/bitbeasts/<theme>/`. The `bitbeast` CLI dynamically switches your Hyprland, Waybar, Kitty, Rofi, Cava, Fastfetch, and wallpaper configurations with a single command.

---

## Prerequisites

The installer automatically detects and installs missing dependencies for `pacman`, `apt`, and `dnf`. However, you can ensure they are present beforehand:

### Required Core
- **Compositor**: `Hyprland`
- **Bar**: `waybar`
- **App Launcher**: `rofi`
- **Terminal**: `kitty`
- **Lockscreen**: `hyprlock`
- **Notifications**: `swaync`
- **Wallpapers**: `swww` (Recommended), `awww`, or `swaybg`
- **System Info**: `fastfetch`
- **Other**: `git`, `bash`, `playerctl`, `cava`, `pipewire`, `wireplumber`

### Recommended Extras
- `brightnessctl` (Backlight control)
- `grim` & `slurp` (Screenshots)
- `pavucontrol` (Audio control)
- `network-manager-applet` & `blueman` (System tray)

### Fonts
You **must** install a Nerd Font for icons to render correctly.
- **JetBrainsMono Nerd Font** (`ttf-jetbrains-mono-nerd`)

---

## Installation Guide

Follow these steps to get BitBeast running on your system:

### 1. Clone the Repository
Open your terminal and clone the repository:
```bash
git clone https://github.com/shivamkumar15/Dranzer.git
cd Dranzer
```

### 2. Make the Installer Executable
Grant execute permissions to the setup script:
```bash
chmod +x install.sh
```

### 3. Run the Setup
Run the installer. We recommend using the `--apply` flag to set everything up immediately:
```bash
./install.sh --apply
```

> [!TIP]
> **Advanced Options:**
> - `--no-deps`: Skip dependency checks if you prefer manual management.
> - `--force`: Overwrite existing configs (backups will still be created).
> - `--theme <name>`: Install and activate a specific theme (e.g., `dragoon`).

---

## Post-Installation

### Add Binaries to PATH
The `bitbeast` CLI is installed to `~/.local/bin`. Ensure this directory is in your `$PATH`.

Add this line to your `.bashrc` or `.zshrc`:
```bash
export PATH="$HOME/.local/bin:$PATH"
```
Then, refresh your shell:
```bash
source ~/.bashrc # or source ~/.zshrc
```

### First Run
Verify the installation by listing themes:
```bash
bitbeast list
```

---

## Usage & Commands

The `bitbeast` command is your main tool for managing themes.

| Command | Description |
| :--- | :--- |
| `bitbeast <theme>` | Apply a specific theme (e.g., `bitbeast dranzer`) |
| `bitbeast pick` | Open an interactive Rofi menu to pick a theme |
| `bitbeast style <name>` | Switch Waybar style (e.g., `bitbeast style glassy`) |
| `bitbeast list` | List all installed themes |

### Fastfetch
The configuration includes a custom Fastfetch layout with BitBeast logos. Run it simply with:
```bash
fastfetch
```

---

## Included Themes

| Theme | Vibe |
| :--- | :--- |
| **Dranzer** | Phoenix Red |
| **Dragoon** | Storm Blue |
| **Driger** | White Tiger |
| **Draciel** | Shield Green |
| **Galeon** | Dark Purple |
| **BurningCerbrus** | Molten Orange |

---

## Backups
Don't worry about your current configs! The installer automatically creates backups here:
`~/.local/state/bitbeast-installer/backups/<timestamp>/`

---

## Troubleshooting

- **Icons are squares**: You forgot to install a Nerd Font!
- **`bitbeast` command not found**: Check your `$PATH` (see Post-Installation).
- **Wallpaper not changing**: Ensure `swww` or `awww` is installed and running.
- **Audio visualizer (Cava) empty**: Check your `~/.config/cava/config` for the correct audio source.

---

Built by [shivamkumar15](https://github.com/shivamkumar15)
