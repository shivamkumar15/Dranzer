# BitBeast Hyprland Dotfiles

A premium, modular Hyprland theme system heavily inspired by Beyblade BitBeasts, featuring high-end Glassmorphism aesthetics and dynamic environment switching.

Each BitBeast is a self-contained profile stored in `~/.config/bitbeasts/<theme>/`. The `bitbeast` CLI seamlessly switches profiles, injecting parameters directly into your active Hyprland, Waybar, Kitty, Rofi, Cava, and wallpaper configs instantly.

## Dependencies

Before installing, ensure you have the required modular components. If your system is missing these, the backend will attempt to fail gracefully, but you will miss out on features:

**Core Requirements:**
- **`waybar`**: Premium floating layout and status handling.
- **`rofi`**: Used for the app launcher, power menu, and dynamic wallpaper selection menus.
- **`kitty`**: Default terminal implementation matching color schemes.
- **`swaync`**: **Required**. Optimized notification center with a beautifully themed HUD drawer.
- **`playerctl`**: **Required**. Powers the live media integration on Waybar.
- **`swaybg`** or **`awww`**: Required. The BitBeast engine relies on these to dynamically transition your desktop backgrounds. **`awww` is highly recommended** to enable the cinematic, unique transition animations for each theme!

**Fonts & Styling (Crucial for the Aesthetic):**
- **JetBrainsMono Nerd Font**: (`ttf-jetbrains-mono-nerd` or similar). Waybar and Rofi rely heavily on Nerd Font/Font Awesome glyphs instead of text strings for their premium floating look. If you see rectangles (`[]`), you are missing these fonts!

**Optional / Recommended:**
- **`pavucontrol`**: Audio mixer for the Pulseaudio module.
- **`blueman`**: Bluetooth management for the Bluetooth module.
- **`network-manager-applet`**: Providing `nm-connection-editor` for network settings.
- **`brightnessctl`** or **`light`**: Note: The `bitbeast` script has a deeply baked-in robust fallback; if neither are installed, it will natively query and manipulate `/sys/class/backlight` directly!

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

> [!IMPORTANT]
> **PATH Configuration**: Ensure `~/.local/bin` is in your `$PATH`. If running `bitbeast` doesn't work after install, add `export PATH="$HOME/.local/bin:$PATH"` to your `.zshrc` or `.bashrc`.

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

### Waybar (Modular Architecture)
The Waybar has been re-engineered with a **fully modular architecture** inspired by the HyDE Project. It features a transparent floating backbone with individual bounding "shares" (leafs on the edges, nested pills in the center).

- **Modular Design**: Individual modules are now stored in `~/.config/waybar/modules/`, making it incredibly easy to swap component logic without touching the main layout.
- **Featured Modules**:
    - **Privacy Guard**: Integrated camera, microphone, and screen-sharing indicators.
    - **Idle Inhibitor**: A "Caffeine" toggle to keep your display awake.
    - **Rich Calendar**: Clock module with a detailed calendar popup and interactive navigation.
    - **Power Menu**: Integrated Rofi-based power management (Shutdown, Reboot, Lock).
- **Theme Bridging**: Your active BitBeast theme colors are dynamically bridged into these modular components using a `theme.css` variable layer.
- Cycle layouts (`Super + Shift + W`) across: `ember`, `glacier`, `forge`, `eclipse`, `throne`.

### Rofi Launcher & Wallpaper Picker
The application launcher and wallpaper pickers are styled as deep-blurred, glowing floating glass bubbles. 
- **High-Contrast Design**: Optimized for readability with pure white text and filled accent highlights.
- **Dynamic Transitions**: When using `awww`, changing wallpapers triggers unique cinematic animations (wipe, wave, outer, grow, simple, center) specific to each BitBeast.
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
- `bitbeast pick` — Opens the immersive Rofi picker for themes on the fly.
- `bitbeast style cycle` — Cycles natively through Waybar structural styles.
- `bitbeast pick-style` — Uses the Rofi picker for Waybar structural styles.
- `bitbeast lock` — Triggers the dynamic theme-aware lockscreen (Hyprlock).
- `bitbeast brightness [up|down]` — Screen brightness control.
- `bitbeast session-init` — Logic to restore your session state on login.

---

## Add a new BitBeast
1. Copy any existing folder from `~/.config/bitbeasts/`.
2. Rename it to the new theme name.
3. Update `colors.conf`, `hyprland.conf`, `waybar.css`, `kitty.conf`, `rofi.rasi`, `cava.conf`, and `wallpaper.conf`.
4. Put the image in the repo root and set `wallpaper.conf` to `@wallpapers/<image-name>`.
5. Run `bitbeast <new-theme>`.

No script changes are needed as long as the new folder follows the same file layout.
