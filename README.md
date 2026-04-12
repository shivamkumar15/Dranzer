# BitBeast Hyprland Dotfiles

A premium, modular Hyprland theme system heavily inspired by Beyblade BitBeasts, featuring high-end Glassmorphism aesthetics and dynamic environment switching.

Each BitBeast is a self-contained profile stored in `~/.config/bitbeasts/<theme>/`. The `bitbeast` CLI seamlessly switches profiles, injecting parameters directly into your active Hyprland, Waybar, Kitty, Rofi, Cava, and wallpaper configs instantly.

## Dependencies

Before installing, ensure you have the required modular components. If your system is missing these, the backend will attempt to fail gracefully, but you will miss out on features:

**Core Requirements:**
- **`waybar`**: Premium floating layout and status handling.
- **`rofi`**: Used for the app launcher and dynamic wallpaper selection menus.
- **`kitty`**: Default terminal implementation matching color schemes.
- **`swaybg`** or **`swww`**: Required. The BitBeast engine relies on these to dynamically transition your desktop backgrounds.

**Fonts & Styling (Crucial for the Aesthetic):**
- **JetBrainsMono Nerd Font**: (`ttf-jetbrains-mono-nerd` or similar). Waybar and Rofi rely heavily on Nerd Font/Font Awesome glyphs instead of text strings for their premium floating look. If you see rectangles (`[]`), you are missing these fonts!

**Optional / Recommended:**
- **Audio Control**: `wireplumber` (`wpctl`). Volume limits are natively clamped at 100% (-l 1.0) internally.
- **Brightness**: `brightnessctl` or `light`. Note: The `bitbeast` script has a deeply baked-in robust fallback; if neither are installed, it will natively query and manipulate `/sys/class/backlight` directly!

## Installation

Clone the repository and run the installer immediately. *Do not run the binaries directly out of your path until the installer configures your environment schemas.*

```bash
git clone https://github.com/shivamkumar15/Dranzer.git
cd Dranzer
chmod +x install.sh

# The standard installation with immediate live-application
./install.sh --apply
```

If you prefer to install a specific theme silently without applying it to the live session immediately:
```bash
./install.sh --theme dragoon
```

### What the installer does:
- Copies the BitBeast profiles into `~/.config/bitbeasts/` and wallpapers into `~/.local/share/bitbeast/wallpapers/`.
- Registers the `bitbeast` CLI utility dynamically to `~/.local/bin/bitbeast`.
- Migrates the Hyprland, Waybar, Kitty, and Rofi configurations into `~/.config/`.
- Backs up any overwritten legacy files into `~/.local/state/bitbeast-installer/backups/`.

---

## Included Themes (Optimized)

All 6 integrated themes have had their alpha layers (glass transparencies), paddings, and borders optimized to perfectly leverage Hyprland's `layerrule = blur` engine. The menus will frosted-glass blur your desktop natively!
- `dranzer`
- `dragoon`
- `driger`
- `draciel` 
- `galeon`
- `burningcerbrus`

## Desktop Integration Features

### Waybar
The Waybar features a fully transparent floating backbone with individual bounding "pills". You can cycle the variants (`Super + Shift + W`), combining BitBeast colors with the styles:
- `ember`, `glacier`, `forge`, `eclipse`, `throne`

### Rofi Launcher
The application launcher and wallpaper pickers are decoupled from the top bar and styled as deep-blurred, glowing floating glass bubbles in the center of your screen. 
- Trigger app search: `SUPER + r`
- Trigger theme selection: `SUPER + w`

### Hyprland Bindings
Hyprland is completely pre-configured to utilize standard system functionality with `bitbeast` abstractions over complex tasks:
- `SUPER + 1..8`: Workspaces
- `SUPER + SHIFT + 1..8`: Move Active Window
- `Volume/Brightness HW Keys`: Dynamically route into `wpctl` and `bitbeast brightness` handlers to prevent overflows.
- `SUPER + s`: Area Screenshots (requires `grim`, `slurp`, and `wl-copy`)

## Commands

Use:
```bash
bitbeast <theme-name>
# Example: bitbeast dragoon
```

**Other available commands:**
- `bitbeast list` — Lists all registered environment themes
- `bitbeast pick` — Opens the immersive Rofi picker populated with real local wallpapers to change your theme on the fly.
- `bitbeast style cycle` — Cycles natively through Waybar structures.
- `bitbeast pick-style` — Uses the Rofi picker for structural layouts.
- `bitbeast brightness [up|down]` — Intelligently raises or lowers screen brightness, falling back sequentially across `brightnessctl` ➔ `light` ➔ `sysfs` without breaking.
- `bitbeast session-init` — Background daemon process called by Hyprland to boot visualizers on login.

---

## Add a new BitBeast
1. Copy any existing folder from `~/.config/bitbeasts/`.
2. Rename it to the new theme name.
3. Update `colors.conf`, `hyprland.conf`, `waybar.css`, `kitty.conf`, `rofi.rasi`, `cava.conf`, and `wallpaper.conf`.
4. Put the image in the repo root and set `wallpaper.conf` to `@wallpapers/<image-name>`.
5. Run `bitbeast <new-theme>`.

No script changes are needed as long as the new folder follows the same file layout.
