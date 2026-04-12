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

# Awesome CAVA patch
CAVA_PATCH = {
    'bars = 36': 'bars = 64',
    'bar_spacing = 2': 'bar_spacing = 1',
    'framerate = 144': 'framerate = 144',
    'sensitivity = 140': 'sensitivity = 180',
    'integral = 82': 'integral = 90',
    'gravity = 110': 'gravity = 130',
    'monstercat = 1': 'monstercat = 1\nnoise_reduction = 0.88',
    'gradient_count = 3': 'gradient_count = 4',
}

base_dir = '/home/sniperxamster/Downloads/Dranzer/.config/bitbeasts'
themes = glob.glob(f'{base_dir}/*')

for theme in themes:
    if not os.path.isdir(theme): continue
    
    # Rofi
    rofi_file = os.path.join(theme, 'rofi.rasi')
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
    cava_file = os.path.join(theme, 'cava.conf')
    if os.path.exists(cava_file):
        with open(cava_file, 'r') as f:
            content = f.read()
            
        for k, v in CAVA_PATCH.items():
            content = content.replace(k, v)
            
        # Ensure we just have 4 gradient colors. Currently there evaluates to 3. Let's add a 4th.
        # Find gradient_color_3
        lines = content.split('\n')
        new_lines = []
        added = False
        for line in lines:
            new_lines.append(line)
            if line.startswith('gradient_color_3'):
                if not added:
                    # just extract the color or default to something
                    new_lines.append("gradient_color_4 = '#ffffff'")
                    added = True
        
        with open(cava_file, 'w') as f:
            f.write('\n'.join(new_lines))

print("Successfully updated Rofi and Cava for all themes.")
