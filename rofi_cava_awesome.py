import os
import glob
import re

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

# Neon Cava Gradients
NEON_GRADIENTS = {
    'dranzer': ['#440000', '#990000', '#FF0000', '#FF4400', '#FF8800', '#FFAA00', '#FFCC00', '#FFEE00'],
    'burningcerbrus': ['#220033', '#440066', '#8800AA', '#AA00FF', '#FF00FF', '#FF44AA', '#FF8844', '#FFCC00'],
    'driger': ['#002200', '#004400', '#008800', '#00FF00', '#44FF00', '#88FF00', '#CCFF00', '#FFFF00'],
    'dragoon': ['#000044', '#000088', '#0000FF', '#0044FF', '#0088FF', '#00CCFF', '#00FFFF', '#AAFFFF'],
    'draciel': ['#001122', '#002244', '#004488', '#0088FF', '#00FFFF', '#88FFFF', '#CCAAFF', '#FFEEFF'],
    'galeon': ['#110022', '#220044', '#440088', '#8800FF', '#CC00FF', '#FF00FF', '#FFBB00', '#FFFF77']
}

base_dir = '/home/sniperxmaster/Dranzer/.config/bitbeasts'
themes = glob.glob(f'{base_dir}/*')

for theme_path in themes:
    if not os.path.isdir(theme_path): continue
    theme_name = os.path.basename(theme_path)
    
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
        # Force a premium configuration
        colors = NEON_GRADIENTS.get(theme_name, NEON_GRADIENTS['dranzer'])
        
        color_block = "[color]\ngradient = 1\n"
        color_block += f"gradient_count = {len(colors)}\n"
        for i, color in enumerate(colors):
            color_block += f"gradient_color_{i+1} = '{color}'\n"
        color_block += "background = '#0a0a0a'\n"
        color_block += f"foreground = '{colors[-2]}'\n"

        cava_config = f"""[general]
bars = 64
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

print("Successfully updated Rofi and Cava for all themes with premium settings.")
