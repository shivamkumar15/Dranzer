# BitBeast Hyprland Dotfiles

A modular Hyprland theme system inspired by Beyblade BitBeasts.

Each BitBeast is a self-contained profile stored in `~/.config/bitbeasts/<theme>/`. The `bitbeast` CLI promotes one of those profiles into the active Hyprland, Waybar, Kitty, Rofi, Cava, and wallpaper config files.

## Dependencies

Before installing, ensure you have a wallpaper daemon installed:
- **`swww`**: Recommended. Supports live transitions and effects. (AUR: `yay -S swww`).
- **`swaybg`**: Supported fallback. Simpler and very stable. (`sudo pacman -S swaybg`).

The system will automatically detect which one is installed and use it.

## Installation

Clone the repo and run:

```sh
chmod +x install.sh
./install.sh
```

Optional:

```sh
./install.sh --theme dragoon
./install.sh --theme dranzer --apply
```

What the installer does:

- copies the BitBeast profiles into `~/.config/bitbeasts/`
- installs wallpapers into `~/.local/share/bitbeast/wallpapers/`
- installs the `bitbeast` CLI to `~/.local/bin/bitbeast`
- copies the Hyprland, Waybar, Kitty, and Rofi config files into `~/.config/`
- installs the shipped Waybar style variants into `~/.config/waybar/styles/`
- activates your selected theme with improved visibility and contrast
- backs up replaced files into `~/.local/state/bitbeast-installer/backups/` unless you use `--force`

If you use `--apply`, the installer also reapplies the selected theme to the live session right away.

## Included themes

All themes have been optimized for maximum visibility and contrast:
- `dranzer`
- `dragoon`
- `driger`
- `draciel` (Updated with a new steel-blue palette for better visibility)
- `galeon`
- `burningcerbrus`

## Included Waybar styles

- `ember`
- `glacier`
- `forge`
- `eclipse`
- `throne`

## Folder structure

```text
.
├── .config
│   ├── bitbeast
│   │   ├── current.conf
│   │   ├── current.style
│   │   ├── current.theme
│   │   └── wallpaper.conf
│   ├── bitbeasts
│   │   ├── <theme>
│   │   │   ├── cava.conf
│   │   │   ├── colors.conf
│   │   │   ├── hyprland.conf
│   │   │   ├── kitty.conf
│   │   │   ├── rofi.rasi
│   │   │   ├── wallpaper.conf
│   │   │   └── waybar.css
│   ├── cava
│   │   └── config
│   ├── hypr
│   │   ├── bitbeast-theme.conf
│   │   └── hyprland.conf
│   ├── kitty
│   │   ├── bitbeast.conf
│   │   └── kitty.conf
│   ├── rofi
│   │   ├── bitbeast.rasi
│   │   └── config.rasi
│   └── waybar
│       ├── bitbeast.css
│       ├── bitbeast-style.css
│       ├── config.jsonc
│       ├── style.css
│       └── styles
│           ├── eclipse.css
│           ├── ember.css
│           ├── forge.css
│           ├── glacier.css
│           └── throne.css
└── .local
    └── bin
        └── bitbeast
```

## What each theme contains

Every profile in `~/.config/bitbeasts/<theme>/` includes:

- `colors.conf`: shared Hyprland color variables for `bg`, `primary`, `secondary`, `accent`, and `text`
- `hyprland.conf`: theme-specific Hyprland snippet, including accent-colored borders
- `waybar.css`: theme color definitions for Waybar
- `kitty.conf`: Kitty terminal palette
- `rofi.rasi`: Rofi launcher theme
- `cava.conf`: Cava visualizer palette and output config
- `wallpaper.conf`: local wallpaper path reference only

## Active files

The switcher copies one BitBeast profile into these active files:

- `~/.config/bitbeast/current.conf`
- `~/.config/bitbeast/current.style`
- `~/.config/bitbeast/current.theme`
- `~/.config/bitbeast/wallpaper.conf`
- `~/.config/hypr/bitbeast-theme.conf`
- `~/.config/waybar/bitbeast.css`
- `~/.config/waybar/bitbeast-style.css`
- `~/.config/kitty/bitbeast.conf`
- `~/.config/rofi/bitbeast.rasi`
- `~/.config/cava/config`

## Commands

Use:

```sh
bitbeast <theme-name>
```

Example:

```sh
bitbeast dragoon
```

Other available commands:

```sh
bitbeast list
bitbeast pick
bitbeast style list
bitbeast style ember
bitbeast style cycle
bitbeast pick-style
bitbeast current-theme
bitbeast current-style
bitbeast restore-wallpaper
bitbeast session-init
```

What `bitbeast <theme-name>` does:

- validates the requested theme exists
- verifies the required files are present
- copies the selected theme into the active config locations
- updates `~/.config/bitbeast/current.conf`, `current.style`, `current.theme`, and `wallpaper.conf`
- restores the wallpaper with swww (or swaybg if swww is missing)
- reloads Hyprland with `hyprctl reload`
- restarts Waybar without leaving duplicate bars behind
- applies Kitty colors when `kitty @` is available

Notes:

- `bitbeast pick` opens a Rofi picker populated with the names of your local wallpapers. Once you select a wallpaper, the system automatically detects and applies the matching BitBeast theme!
- `bitbeast pick-style` opens a Rofi picker for the shipped Waybar style variants
- `bitbeast style cycle` rotates through the installed Waybar looks and restarts Waybar
- clicking the `beast`, `style`, and `wall` modules in Waybar gives quick access to theme switching, style cycling, and wallpaper restore
- choosing a wallpaper from the picker automatically applies the matching theme
- `bitbeast restore-wallpaper` restores the saved wallpaper from the current BitBeast state
- `bitbeast session-init` restores the wallpaper before restarting Waybar
- `cava` reads the updated config on next launch; if it is already running, restart it once after switching themes
- wallpapers are installed into `~/.local/share/bitbeast/wallpapers/`

## Hyprland integration

Hyprland reads:

- `~/.config/bitbeast/current.conf`
- `~/.config/hypr/bitbeast-theme.conf`

The default Hyprland config includes:

- `exec-once = ~/.local/bin/bitbeast session-init`
- 8 persistent workspaces: `1` through `8`
- `SUPER + 1..8` to switch workspaces
- `SUPER + SHIFT + 1..8` to move the active window to a workspace
- `SUPER + r` to open Rofi drun
- `SUPER + w` to open the Rofi picker to select your BitBeast wallpaper!
- `SUPER + b` to open the browser
- `SUPER + Return` to open the terminal
- `SUPER + q` to kill the active window
- `SUPER + f` to toggle fullscreen
- `SUPER + space` to toggle floating

## Waybar integration

Waybar reads:

- `~/.config/waybar/style.css`
- `~/.config/waybar/bitbeast.css`
- `~/.config/waybar/bitbeast-style.css`
- `~/.config/waybar/config.jsonc`

The shipped Waybar config now includes:

- persistent workspace buttons for `1` through `8`
- clickable `beast`, `style`, and `wall` controls
- interactive `cpu` and `ram` status modules (click for a system monitor)
- interactive `network` module (click for network manager UI)
- interactive `backlight` brightness control (scroll over it to adjust screen brightness natively)
- five switchable style variants layered on top of each BitBeast color palette

## App integration

Kitty reads:

- `~/.config/kitty/kitty.conf`
- `~/.config/kitty/bitbeast.conf`

Rofi reads:

- `~/.config/rofi/config.rasi`
- `~/.config/rofi/bitbeast.rasi`

Cava reads:

- `~/.config/cava/config`

## Add a new BitBeast

1. Copy any existing folder from `~/.config/bitbeasts/`.
2. Rename it to the new theme name.
3. Update `colors.conf`, `hyprland.conf`, `waybar.css`, `kitty.conf`, `rofi.rasi`, `cava.conf`, and `wallpaper.conf`.
4. Put the image in the repo root and set `wallpaper.conf` to `@wallpapers/<image-name>`.
5. Run `bitbeast <new-theme>`.

No script changes are needed as long as the new folder follows the same file layout.

## Wallpaper mapping

These profiles map to the local wallpapers already in this repository:

- `dranzer` -> `Dranzer.png`
- `dragoon` -> `Dragoon.png`
- `driger` -> `Drigger.png`
- `draciel` -> `Dracel.png`
- `galeon` -> `Galeon.png`
- `burningcerbrus` -> `BurningCerbrus.png`

The `driger` and `draciel` profile names intentionally map to the existing local filenames `Drigger.png` and `Dracel.png`.
