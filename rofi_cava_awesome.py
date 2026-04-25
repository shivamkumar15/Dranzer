import os
import glob
import re
import subprocess

# Awesome Rofi CSS patch
ROFI_PATCH = """
window {
    location: center;
    anchor: center;
    fullscreen: false;
    width: 750px;
    border: 3px solid;
    border-radius: 30px;
    border-color: @accent;
    background-color: @bg;
    box-shadow: 0px 0px 20px 5px rgba(0,0,0,0.5);
}

mainbox {
    children: [ inputbar, listview, mode-switcher ];
    spacing: 20px;
    padding: 35px;
    background-color: transparent;
}

inputbar {
    children: [ prompt, entry ];
    spacing: 15px;
    padding: 20px 25px;
    border-radius: 20px;
    background-color: @bg-alt;
    text-color: @text;
}

prompt {
    text-color: @accent;
    font: "JetBrainsMono Nerd Font Bold 16";
    str: "  ";
}

entry {
    placeholder: "Search applications, ignite the Beast...";
    placeholder-color: @muted;
    text-color: @text;
    font: "JetBrainsMono Nerd Font 14";
}

listview {
    lines: 7;
    columns: 2;
    fixed-height: false;
    border: 0px;
    spacing: 12px;
    background-color: transparent;
    scrollbar: false;
}

element {
    padding: 16px 20px;
    border-radius: 18px;
    background-color: transparent;
    text-color: @text;
}

element normal.normal { background-color: transparent; text-color: @text; }
element selected.normal { background-color: transparent; border: 2px solid; border-color: @accent; border-radius: 18px; text-color: @accent; box-shadow: 0px 0px 10px @accent; }
element selected.active { background-color: transparent; border: 2px solid; border-color: @primary; border-radius: 18px; text-color: @primary; }
element selected.urgent { background-color: transparent; border: 2px solid; border-color: @urgent; border-radius: 18px; text-color: @urgent; }
element alternate.normal { background-color: transparent; text-color: @text; }
element alternate.active { background-color: transparent; text-color: @text; }
element alternate.urgent { background-color: transparent; text-color: @urgent; }

element-icon { size: 36px; vertical-align: 0.5; }
element-text { text-color: inherit; vertical-align: 0.5; font: "JetBrainsMono Nerd Font 13"; }

mode-switcher { spacing: 15px; background-color: transparent; }

button {
    padding: 12px 18px;
    border-radius: 999px;
    background-color: @bg-alt;
    text-color: @muted;
    font: "JetBrainsMono Nerd Font Bold 13";
}

button selected { background-color: @primary; text-color: #ffffff; box-shadow: 0px 0px 15px @primary; }
"""

# Theme to Wallpaper mapping is now dynamic via wallpaper.conf
REPO_DIR = '/home/sniperxmaster/Dranzer'
BASE_DIR = os.path.join(REPO_DIR, '.config/bitbeasts')
WALLPAPER_DIR = REPO_DIR # Default in repo

def resolve_wallpaper_path(wallpaper_value):
    if wallpaper_value.startswith("@wallpapers/"):
        return os.path.join(WALLPAPER_DIR, wallpaper_value.replace("@wallpapers/", ""))
    elif wallpaper_value.startswith("~/"):
        return os.path.expanduser(wallpaper_value)
    return wallpaper_value

def extract_colors(wallpaper_path, count=8):
    if not os.path.exists(wallpaper_path):
        print(f"Warning: Wallpaper not found: {wallpaper_path}")
        return None
    
    try:
        # Use magick to extract dominant colors
        cmd = [
            "magick", wallpaper_path, 
            "-colors", str(count), 
            "-format", "%c", "histogram:info:"
        ]
        result = subprocess.check_output(cmd).decode()
        
        # Parse hex colors from output
        colors = re.findall(r'#([0-9A-Fa-f]{6})', result)
        
        # Sort colors by luminance for a smooth gradient
        def get_luminance(hex_color):
            r = int(hex_color[0:2], 16)
            g = int(hex_color[2:4], 16)
            b = int(hex_color[4:6], 16)
            return 0.299*r + 0.587*g + 0.114*b
        
        colors.sort(key=get_luminance)
        return ['#' + c for c in colors]
    except Exception as e:
        print(f"Error extracting colors from {wallpaper_path}: {e}")
        return None

themes = glob.glob(f'{BASE_DIR}/*')

for theme_path in themes:
    if not os.path.isdir(theme_path): continue
    theme_name = os.path.basename(theme_path)
    
    print(f"Processing theme: {theme_name}")
    
    # Rofi
    rofi_file = os.path.join(theme_path, 'rofi.rasi')
    if os.path.exists(rofi_file):
        with open(rofi_file, 'r') as f:
            content = f.read()
        
        # Keep only the defining block `* { ... }`
        top_block = []
        for line in content.split('\n'):
            top_block.append(line)
            if line.strip() == '}':
                break
                
        new_content = '\n'.join(top_block) + '\n\n' + ROFI_PATCH.strip() + '\n'
        with open(rofi_file, 'w') as f:
            f.write(new_content)
            
    # Cava
    cava_file = os.path.join(theme_path, 'cava.conf')
    if os.path.exists(cava_file):
        # Dynamically extract colors from wallpaper.conf
        colors = None
        wallpaper_conf = os.path.join(theme_path, 'wallpaper.conf')
        if os.path.exists(wallpaper_conf):
            with open(wallpaper_conf, 'r') as f:
                conf_content = f.read()
                match = re.search(r'wallpaper\s*=\s*["\']?([^"\']+)["\']?', conf_content)
                if match:
                    wallpaper_path = resolve_wallpaper_path(match.group(1))
                    colors = extract_colors(wallpaper_path)
        
        # Fallback to a default red gradient if extraction fails
        if not colors:
            colors = ['#440000', '#990000', '#FF0000', '#FF4400', '#FF8800', '#FFAA00', '#FFCC00', '#FFEE00']
        
        # Ensure we have exactly 8 colors for the gradient
        if len(colors) < 8:
            # Duplicate the last color if needed
            while len(colors) < 8:
                colors.append(colors[-1])
        elif len(colors) > 8:
            colors = colors[:8]

        color_block = "[color]\ngradient = 1\n"
        color_block += f"gradient_count = {len(colors)}\n"
        for i, color in enumerate(colors):
            color_block += f"gradient_color_{i+1} = '{color}'\n"
        
        # Use the darkest color for background (if available)
        bg_color = colors[0] if colors else '#0a0a0a'
        # Use a bright color for foreground
        fg_color = colors[-2] if len(colors) > 1 else '#ffffff'
        
        color_block += f"background = '#0a0a0a'\n" # Keep background dark for premium look
        color_block += f"foreground = '{fg_color}'\n"

        cava_config = f"""[general]
bars = 0
bar_width = 2
bar_spacing = 1
framerate = 144
sensitivity = 100
autosens = 1

[input]
method = pulse
source = auto

[output]
method = ncurses
channels = mono
mono_option = average

[smoothing]
integral = 95
monstercat = 1
noise_reduction = 0.88
waves = 0
gravity = 140

{color_block}
"""
        with open(cava_file, 'w') as f:
            f.write(cava_config)

print("\nSuccessfully updated Rofi and Cava for all themes with dynamic wallpaper-matched colors.")
