# BitBeast Hyprland Dotfiles

A modular Hyprland theme system inspired by Beyblade BitBeasts. Each theme installs into `~/.config/bitbeasts/<theme>/` and the `bitbeast` CLI switches your Hyprland, Waybar, Kitty, Rofi, Cava, and wallpaper configurations.

## Prerequisites

### Required packages
Install the following packages before running the installer:

- `waybar`
- `rofi`
- `kitty`
- `hyprlock`
- `swaync`
- `playerctl`
- `cava`
- `swww` or `swaybg` (at least one wallpaper backend)
- `git`
- `bash` or another POSIX shell
- A Wayland compositor such as `Hyprland`

### Recommended packages

These packages are optional but improve the experience and support keybindings:

- `brightnessctl` or `light`
- `wpctl`
- `grim`
- `slurp`
- `wl-copy`
- `pavucontrol`
- `network-manager-applet`
- `blueman`

### Fonts

Install a Nerd Font so Waybar and Rofi display icons correctly:

- JetBrainsMono Nerd Font (`ttf-jetbrains-mono-nerd` or similar)

If you see rectangles like `[]`, the Nerd Font is missing.

## Installation

1. Clone the repository:

```bash
git clone https://github.com/shivamkumar15/Dranzer.git
cd Dranzer
```

2. Make the installer executable:

```bash
chmod +x install.sh
```

3. Run the installer:

```bash
./install.sh --apply
```

This installs the configuration files and applies the selected theme immediately.

### Install a specific theme only

```bash
./install.sh --theme dragoon
```

### Force overwrite existing files

```bash
./install.sh --force --apply
```

## What the installer does

- Copies theme folders from `.config/bitbeasts/` into `~/.config/bitbeasts/`
- Copies wallpapers into `~/.local/share/bitbeast/wallpapers/`
- Copies Hyprland and Hyprlock configuration into `~/.config/hypr/`
- Copies Waybar config into `~/.config/waybar/`
- Copies Kitty config into `~/.config/kitty/`
- Copies Rofi config into `~/.config/rofi/`
- Copies Swaync config into `~/.config/swaync/`
- Installs CLI scripts into `~/.local/bin/`
- Writes current theme/style state into `~/.config/bitbeast/`

## Required environment setup

### Add `~/.local/bin` to your PATH

If `bitbeast` is not found after install, add this to your shell config:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Then reload your shell:

```bash
source ~/.bashrc
# or
source ~/.zshrc
```

### Verify installation

```bash
command -v bitbeast
bitbeast list
```

### Restart your Wayland session

After installation, log out and log back in or restart your Hyprland session to ensure all config files load correctly.

## Usage

Apply a theme:

```bash
bitbeast dragoon
```

Pick a theme interactively:

```bash
bitbeast pick
```

Switch Waybar style:

```bash
bitbeast style <style-name>
```

List installed themes:

```bash
bitbeast list
```

## Included themes

- `dranzer`
- `dragoon`
- `driger`
- `draciel`
- `galeon`
- `burningcerbrus`

## Backups

If existing files are overwritten, backups are stored under:

- `~/.local/state/bitbeast-installer/backups/<timestamp>/`

## Troubleshooting

- If `bitbeast` is not found: ensure `~/.local/bin` is in your `$PATH`
- If a theme fails: verify that required tools are installed and the wallpaper backend (`swww` or `swaybg`) exists
- If icons are missing: install a Nerd Font
- If audio isn't detected: check that your audio source is set correctly in Cava config

## Adding a new BitBeast

1. Copy an existing theme folder from `~/.config/bitbeasts/`
2. Rename it to the new theme name
3. Update config files:
   - `colors.conf`
   - `hyprland.conf`
   - `waybar.css`
   - `kitty.conf`
   - `rofi.rasi`
   - `cava.conf`
   - `wallpaper.conf`
4. Add the wallpaper image to the repo root
5. Set `wallpaper.conf` to `@wallpapers/<image-name>`
6. Run:

```bash
bitbeast <new-theme>
```

No script changes are required as long as the folder structure remains consistent.
