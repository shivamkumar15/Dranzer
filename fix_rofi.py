def process_file(path):
    with open(path, 'r') as f:
        lines = f.readlines()
        
    start_idx = -1
    end_idx = -1
    
    for i, line in enumerate(lines):
        if line.startswith("build_rofi_theme() {"):
            start_idx = i
        elif line.startswith("resolve_wallpaper_path() {"):
            end_idx = i - 1
            break
            
    if start_idx != -1 and end_idx != -1:
        new_func = """build_rofi_theme() {
    theme_dir=$1
    target_path=$2
    colors_file=$3
    require_file "$colors_file"

    bg=$(theme_color_hex "$colors_file" bg '#0a0b10')
    primary=$(theme_color_hex "$colors_file" primary '#00f2ff')
    secondary=$(theme_color_hex "$colors_file" secondary '#7000ff')
    accent=$(theme_color_hex "$colors_file" accent '#00f2ff')
    text=$(theme_color_hex "$colors_file" text '#e0e6ed')
    muted="${text}99"
    prompt_text="$(basename "$theme_dir")"

    mkdir -p "$(dirname "$target_path")"
    cat > "$target_path" <<EOF_ROFI
* {
    bg: ${bg}f2;
    bg-alt: ${secondary}cc;
    primary: ${primary};
    accent: ${accent};
    text: ${text};
    muted: ${muted};
    urgent: #ff0055;
    border: 2px;
    spacing: 14px;
    background-color: transparent;
}

window {
    location: center;
    anchor: center;
    fullscreen: false;
    width: 720px;
    border: @border;
    border-radius: 22px;
    border-color: @accent;
    background-color: @bg;
}

mainbox {
    children: [ inputbar, listview, mode-switcher ];
    spacing: 18px;
    padding: 22px;
    background-color: transparent;
}

inputbar {
    children: [ prompt, entry ];
    spacing: 12px;
    padding: 14px 18px;
    border-radius: 16px;
    background-color: @bg-alt;
    text-color: @text;
}

prompt {
    text-color: @accent;
    str: "${prompt_text}";
}

entry {
    placeholder: "Ignite the launch";
    placeholder-color: @muted;
    text-color: @text;
}

listview {
    lines: 8;
    columns: 1;
    fixed-height: false;
    border: 0px;
    background-color: transparent;
    scrollbar: false;
}

element {
    padding: 14px 16px;
    border-radius: 16px;
    background-color: transparent;
    text-color: @text;
}

element normal.normal { background-color: transparent; text-color: @text; }
element selected.normal { background-color: @primary; text-color: #0a0b10; }
element selected.active { background-color: @secondary; text-color: @text; }
element selected.urgent { background-color: @urgent; text-color: #0a0b10; }
element alternate.normal { background-color: transparent; text-color: @text; }
element alternate.active { background-color: transparent; text-color: @accent; }
element alternate.urgent { background-color: transparent; text-color: @urgent; }

element-icon { size: 28px; vertical-align: 0.5; background-color: transparent; }
element-text { text-color: inherit; vertical-align: 0.5; background-color: transparent; }

mode-switcher { spacing: 10px; background-color: transparent; }

button {
    padding: 10px 14px;
    border-radius: 999px;
    background-color: @bg-alt;
    text-color: @muted;
}

button selected { background-color: @primary; text-color: #0a0b10; }
EOF_ROFI
}

"""
        new_lines = lines[:start_idx] + [new_func] + lines[end_idx:]
        with open(path, 'w') as f:
            f.writelines(new_lines)
        print(f"Patched {path}")

process_file(".local/bin/bitbeast")
process_file(".local/bin/bitbeast.sh")
