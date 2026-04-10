# BitBeast Hyprland Dotfiles

A modular Hyprland theme system inspired by Beyblade BitBeasts.

Each BitBeast is a self-contained theme profile stored in `~/.config/bitbeasts/<theme>/`. The `bitbeast` CLI promotes one of those profiles into the active Hyprland, Waybar, Kitty, Rofi, Cava, and wallpaper config files.

## Included themes

- `dranzer`
- `dragoon`
- `driger`
- `draciel`
- `galeon`
- `burningcerbrus`

## Folder structure

```text
.
├── .config
│   ├── bitbeast
│   │   ├── current.conf
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
│       ├── config.jsonc
│       └── style.css
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
- `~/.config/bitbeast/current.theme`
- `~/.config/bitbeast/wallpaper.conf`
- `~/.config/hypr/bitbeast-theme.conf`
- `~/.config/waybar/bitbeast.css`
- `~/.config/kitty/bitbeast.conf`
- `~/.config/rofi/bitbeast.rasi`
- `~/.config/cava/config`

## Switching themes

Use:

```sh
bitbeast <theme-name>
```

Example:

```sh
bitbeast dragoon
```

The switcher will:

- validate the requested theme exists
- verify the required files are present
- copy the theme into the active config locations
- update `~/.config/bitbeast/current.conf`
- set the wallpaper with `swww img`
- reload Hyprland with `hyprctl reload`
- restart Waybar
- apply Kitty colors when `kitty @` is available

Notes:

- `cava` reads the updated config on next launch; if it is already running, restart it once after switching themes
- wallpapers are always local file paths from this repository

## Hyprland integration

Hyprland reads:

- `~/.config/bitbeast/current.conf`
- `~/.config/hypr/bitbeast-theme.conf`

The launcher binding in `~/.config/hypr/hyprland.conf` is set to:

```text
SUPER + R -> rofi -show drun -config ~/.config/rofi/config.rasi
```

## App integration

Waybar reads:

- `~/.config/waybar/style.css`
- `~/.config/waybar/bitbeast.css`

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
4. Point `wallpaper.conf` to an existing local image path.
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
