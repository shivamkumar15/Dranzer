import os
import glob

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

# Awesome CAVA patch (Generic settings)
CAVA_PATCH = {
    'bars = 36': 'bars = 64',
    'bar_width = 3': 'bar_width = 1',
    'bar_spacing = 2': 'bar_spacing = 0',
    'framerate = 144': 'framerate = 144',
    'sensitivity = 140': 'sensitivity = 180',
    'integral = 82': 'integral = 95',
    'gravity = 110': 'gravity = 140',
    'monstercat = 1': 'monstercat = 1\nnoise_reduction = 0.88',
}

base_dir = '/home/sniperxamster/Downloads/Dranzer/.config/bitbeasts'
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
        in_block = False
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
        with open(cava_file, 'r') as f:
            content = f.read()
            
        # Standardize smoothing and general settings first
        # Replace the entire [smoothing] section for consistency
        smoothing_block = "[smoothing]\nintegral = 95\nmonstercat = 1\nnoise_reduction = 0.88\nwaves = 0\ngravity = 140\n"
        
        import re
        content = re.sub(r'\[smoothing\].*?(?=\n\[|$)', smoothing_block, content, flags=re.DOTALL)
        
        # Apply other generic patches
        for k, v in CAVA_PATCH.items():
            if 'monstercat' in k: continue # Handled in smoothing block
            content = content.replace(k, v)
        
        # Rewrite [color] section
        colors = NEON_GRADIENTS.get(theme_name, NEON_GRADIENTS['dranzer'])
        color_block = "[color]\ngradient = 1\n"
        color_block += f"gradient_count = {len(colors)}\n"
        for i, color in enumerate(colors):
            color_block += f"gradient_color_{i+1} = '{color}'\n"
        
        # Try to preserve background/foreground if they exist in the current content
        bg_match = re.search(r'^background\s*=\s*(.*)', content, re.MULTILINE)
        fg_match = re.search(r'^foreground\s*=\s*(.*)', content, re.MULTILINE)
        
        if bg_match: color_block += f"background = {bg_match.group(1).strip()}\n"
        else: color_block += "background = '#0a0a0a'\n" # Fallback
        
        if fg_match: color_block += f"foreground = {fg_match.group(1).strip()}\n"
        else: color_block += f"foreground = '{colors[-2]}'\n" # Use one of the neon colors as fallback
            
        content = re.sub(r'\[color\].*?(?=\n\[|$)', color_block, content, flags=re.DOTALL)
        
        with open(cava_file, 'w') as f:
            f.write(content.strip() + '\n')

print("Successfully updated Rofi and Cava for all themes.")
