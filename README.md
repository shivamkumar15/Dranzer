# BitBeast Hyprland Dotfiles

A modular, premium Hyprland theme system inspired by Beyblade BitBeasts.

> [!NOTE]
> Each theme installs into `~/.config/bitbeasts/<theme>/`. The `bitbeast` CLI dynamically switches your Hyprland, Waybar, Kitty, Rofi, Cava, Fastfetch, and wallpaper configurations with a single command.

> [!NOTE]
> **Hyprland 0.57+ compatibility:** Hyprland 0.57 reads `~/.config/hypr/hyprland.lua`. The installer writes both the Lua config (for 0.57+) and the legacy `hyprland.conf` (for older releases), so the same clone works on either. The Lua config re-reads the BitBeast theme and touchpad state on every reload, so `bitbeast <theme>`, `bitbeast style ...`, and `bitbeast touchpad` keep working. The wallpaper is restored at session start and whenever the theme changes.

---
## Screenshots <img width="1920" height="1076" alt="2026-06-01-123100" src="https://github.com/user-attachments/assets/9d07a1aa-9985-4626-adc2-6622f7caed19" />
<img width="1916" height="1073" alt="2026-06-01-122839" src="https://github.com/user-attachments/assets/bed4bf83-4376-4d8a-b99f-53ef34014dde" />
<img width="1917" height="1079" alt="2026-06-01-122830" src="https://github.com/user-attachments/assets/511198ba-2fed-492c-bfc6-729147904264" />
<img width="1920" height="1080" alt="2026-06-01-122823" src="https://github.com/user-attachments/assets/d56d1ced-ef52-426e-bf8c-338c269c7dd7" />
<img width="1920" height="1080" alt="2026-06-01-122814" src="https://github.com/user-attachments/assets/587a2946-fdd5-4d86-ac76-3fdb4cde9507" />
Different bitbeast have different color theme

## Prerequisites

`./install.sh` detects your package manager and installs missing packages automatically on Arch-based (`pacman`/`yay`/`paru`), Debian/Ubuntu (`apt`), and Fedora (`dnf`) systems. Package names and availability vary by distribution; if a required package cannot be installed, the installer stops and lists what is missing. Optional extras are attempted separately, so one unavailable optional package cannot abort the install. On Arch, a fresh clone needs no manual package installation; on other distributions you may need to install Hyprland and its development headers from a third-party repository.

### Required Core
- **Compositor**: `Hyprland`
- **Bar**: `waybar`
- **App Launcher**: `rofi`
- **Terminal**: `kitty`
- **Lockscreen**: `hyprlock`
- **Notifications**: `swaync`
- **Wallpapers**: `swaybg` (installed automatically; `swww`/`awww` are optional)
- **Wallpaper picker**: GTK 3, PyGObject, GtkLayerShell, and WebKit2GTK 4.1 or 4.0
- **System Info**: `fastfetch` (recommended)
- **Networking**: `NetworkManager` (`nmcli`) and `bluez` / `bluez-utils` (`bluetoothctl`) (recommended)
- **Screenshots/clipboard**: `grim`, `slurp`, `wl-clipboard`, `cliphist`
- **Brightness**: `brightnessctl`
- **Other**: `git`, `bash`, `zsh`, `playerctl`, `cava`, `pipewire`, `wireplumber`, `pactl` (PipeWire PulseAudio), `jq`, `bc`, `libnotify`, `xdg-utils`
- **Build tools for Hyprspace**: `make`, `gcc`/`g++`, `pkg-config`, plus the Hyprland headers (`pkg-config --exists hyprland`)

### Optional
- `pavucontrol`, `nm-applet`, `blueman`, `ImageMagick`, `power-profiles-daemon`, `curl`, `dolphin`, `yazi`, and a browser (`google-chrome-stable`, `chromium`, `firefox`, etc.).
- If no browser is found, the installer tries to install Firefox, and the `bitbeast-browser` helper picks whichever browser is available at runtime.

### Fonts
You **must** install a Nerd Font for icons to render correctly.
- **JetBrainsMono Nerd Font** (`ttf-jetbrains-mono-nerd` on Arch; package names vary elsewhere)

---

## Installation Guide

Follow these steps to get BitBeast running on your system:

### 1. Clone the Repository
Open your terminal and clone the repository:
```bash
git clone https://github.com/shivamkumar15/Dranzer.git
cd Dranzer
```

### 2. Run the Setup
```bash
chmod +x install.sh
./install.sh
```

If you are already inside a running Hyprland session and want the theme, Waybar, and wallpaper reloaded immediately, use `./install.sh --apply` instead.

The installer will:

- Detect your package manager and install missing required packages, then try optional extras without failing the whole install.
- Back up any config it replaces under `~/.local/state/bitbeast-installer/backups/<timestamp>/`.
- Install the Lua config for Hyprland 0.57+ and the legacy config for older releases.
- Detect your touchpad and write a matching `~/.config/hypr/touchpad.conf`.
- Install Oh My Zsh, the BitBeast zsh theme, and the prompt helpers (already-present installations are reused).
- Build the Hyprspace workspace-overview plugin for the installed Hyprland version.
- Enable NetworkManager, Bluetooth, and power-profiles-daemon when they are installed.
- Add `~/.local/bin` to your shell PATH and install the touchpad udev rule for the volume-gesture daemon.

> [!TIP]
> **Advanced Options:**
> - `--no-deps`: Skip dependency checks if you prefer manual management.
> - `--skip-system`: Do not enable services or install the touchpad udev rule.
> - `--skip-hyprspace`: Do not download/build the Hyprspace plugin.
> - `--skip-zsh`: Do not install or configure Oh My Zsh.
> - `--force`: Overwrite existing configs without keeping a backup.
> - `--theme <name>`: Install and activate a specific theme (e.g., `dragoon`).

---

## Post-Installation

### Log Into Hyprland
Log out and choose **Hyprland** from your display manager (or run `Hyprland` from a TTY). On Hyprland 0.57+, `~/.config/hypr/hyprland.lua` is loaded automatically. The legacy `~/.config/hypr/hyprland.conf` remains for older versions.

### PATH
The installer adds `~/.local/bin` to `.zshrc` and to existing `.bashrc` / `.profile` files. Start a new shell (or log out and back in) before calling `bitbeast`.

### First Run
Verify the installation by listing themes:
```bash
bitbeast list
```

---

## Usage & Commands

The `bitbeast` command is your main tool for managing theme

### Keyboard Hints Panel
Press **`Super + H`** at any time to open the premium keyboard shortcuts panel. It features a masonry layout, live search, and dynamic grouping directly generated from your `hyprland.conf` comments.

### Control Center (Quick Settings + Power Panel)
Press **`Super + C`** to open the macOS-style control center. It is a single panel with two columns: quick settings on the left, and the live system / power column on the right.

The Wi-Fi and Bluetooth rows open a full detail popover:

- **Wi-Fi** — live network list with signal strength, lock badges, saved/connected state, Rescan, `Other Network…` (including hidden SSIDs), inline password entry, Disconnect, and enterprise-network handoff.
- **Bluetooth** — power switch, connected/paired/nearby devices, device-type icons, battery percentage, pairing/connecting, disconnecting, and manual scan.
- The Waybar Wi-Fi and Bluetooth icons open the matching panel directly (`bitbeast-control-center show wifi` / `show bluetooth`), while `Super + C` still toggles the whole panel.

The right column carries the power panel that used to live in `bitbeast-power-popup`:

- **Clock** with live CPU / RAM / Disk / Battery chips.
- **Notifications** — summary with a DND hint, click to open the swaync panel.
- **Now Playing** — track, artist, progress bar and previous / play-pause / next transport.
- **Quick Toggles** — Airplane mode and Network Settings (`nmtui`).
- **Session** — Suspend, Logout, Restart and Shutdown via `bitbeast-session`.
- The Waybar clock and power icons open the same panel, so there is one launcher: `bitbeast-control-center`.

### Waybar Styles
The system ships with **18** Waybar styles. Each style has **high-contrast theme colors** (readable text) and a matching **module layout**.

| Style | Look | Modules |
| :--- | :--- | :--- |
| `azure` / `edges` | Continuous solid bar | Dense sysinfo (cpu/temp/load/mem/net/cava + clock/power) |
| `hud` / `pill` / `carbon` / `glass` / `monochrome` | Grouped chrome | Classic (workspaces, cava, media, essentials) |
| `clean` / `plain` / `flat` / `underline` | Low chrome | Sparse (workspaces, window, clock, net, battery, audio) |
| `arrow` / `blocks` / `bubble` / `rainbow` / `eclipse` | Segmented tiles | Segments (cpu/mem/net · clock/media · controls) |
| `neon` / `pulse` | Glow modules | Glow (cava + media focus) |

All styles use theme `@bg` / `@text` / `@primary` / `@glow` so colors match Dranzer, Dragoon, Driger, etc., with solid enough backgrounds that text stays readable on bright wallpapers.

```bash
bitbeast style clean        # apply a style
bitbeast style list         # list all styles
bitbeast pick-style         # Rofi menu
bitbeast style cycle        # next style
```

| Shortcut | Action |
| :--- | :--- |
| `Super + Shift + B` | Open the style picker (Rofi menu) |
| `Super + Shift + W` | Cycle to the next style |
| `Super + W` | Open the theme picker (Rofi menu) |

### Fastfetch
The configuration includes a custom Fastfetch layout with BitBeast logos. Run it simply with:
```bash
fastfetch
```

### Cava Visualizers
Three cava profiles are available after installation:

| Command | What it does |
| :--- | :--- |
| `cava` | Terminal bars colored by the active BitBeast theme (`~/.config/cava/config`) |
| `cava-j` | Terminal bars with the purple/blue/red gradient profile (`~/.config/cava/josh.conf`) |
| `cava-spiral` | Rotating Orion ring visualizer in an SDL/OpenGL window (`~/.config/cava/spiral.conf`) |

The profile configs are installed to `~/.config/cava/`, and the GLSL shaders used by `cava-spiral` are installed to `~/.config/cava/shaders/`.

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
- **`bitbeast` command not found**: Start a new shell or check that `~/.local/bin` is in `$PATH` (the installer adds it).
- **Wallpaper not changing**: `swaybg` is installed by default; `swww`/`awww` are optional. Check which backend is available with `command -v swaybg swww awww`.
- **Wallpaper picker is blank**: Install WebKit2GTK 4.1 (or 4.0) and PyGObject, then rerun `./install.sh`. The selector uses the GTK layer shell when available and a fullscreen GTK window otherwise.
- **Super+B does not open a browser**: Run `bitbeast-browser`, or set `BITBEAST_BROWSER` to your browser command and restart Hyprland.
- **Hyprspace overview is missing**: Run `bitbeast-hyprspace build` after installing `make`, `gcc`/`g++`, `pkg-config`, and the Hyprland development headers. On Hyprland 0.57 the stock upstream plugin is used.
- **Audio visualizer (Cava) empty**: Check your `~/.config/cava/config` for the correct audio source.
- **`zsh: corrupt history file`**: This is caused by a concurrent-shell history write race. The `.zshrc` now uses `INC_APPEND_HISTORY` with `HIST_FCNTL_LOCK` exclusively (the redundant `APPEND_HISTORY` exit-time append has been removed). Delete any stale `~/.zsh_history.corrupt.*` / `.bad` / `.backup` files. If it persists, run `fc -W` to flush the current session and restart your shell.

---

Built by [shivamkumar15](https://github.com/shivamkumar15)
