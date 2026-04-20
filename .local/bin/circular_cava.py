#!/usr/bin/env python3

import os
import sys
import math
import time
import signal
import shutil
import select
import subprocess
import struct


# Braille dot mapping
BRAILLE_DOTS = [
    [0x01, 0x08],
    [0x02, 0x10],
    [0x04, 0x20],
    [0x40, 0x80]
]

class CircularCava:
    def __init__(self, bars=64, radius=12, colors=None, mode='wave'):
        self.bars = bars
        self.radius = radius
        self.colors = colors
        self.mode = mode
        self.fifo_path = "/tmp/cava_circular_fifo"
        self.cava_proc = None
        self.running = True
        
        # Terminal setup
        self.update_dimensions()
        
        # Initial color load
        if not self.colors:
            self.load_colors_from_state()
        if not self.colors:
            self.colors = ['#FF0000', '#FF8800', '#FFFF00']

    def load_colors_from_state(self, signum=None, frame=None):
        config_path = os.path.expanduser("~/.config/bitbeast/current.conf")
        if not os.path.exists(config_path):
            return
        
        color_map = {}
        try:
            with open(config_path, "r") as f:
                for line in f:
                    if "=" in line and "rgb(" in line:
                        name = line.split("=")[0].strip().lstrip("$")
                        color_hex = line.split("rgb(")[1].split(")")[0]
                        color_map[name] = f"#{color_hex}"
            
            ordered_names = ["bg", "secondary", "primary", "accent", "text"]
            new_colors = [color_map[name] for name in ordered_names if name in color_map]
            
            if new_colors:
                self.colors = new_colors
                # Clear screen to force full redraw with new colors
                sys.stdout.write("\033[2J")
                sys.stdout.flush()
        except Exception:
            pass
        
    def update_dimensions(self):
        self.cols, self.rows = shutil.get_terminal_size()
        self.canvas_width = self.cols * 2
        # Ensure rows is at least 2 to avoid negative height
        rows = max(2, self.rows)
        self.canvas_height = (rows - 2) * 4
        
        # Center of canvas
        self.cx = self.canvas_width // 2
        self.cy = self.canvas_height // 2

    def handle_resize(self, signum=None, frame=None):
        self.update_dimensions()
        # Clear screen on resize to avoid artifacts
        sys.stdout.write("\033[2J")
        sys.stdout.flush()

    def setup_cava(self):
        if os.path.exists(self.fifo_path):
            os.remove(self.fifo_path)
        os.mkfifo(self.fifo_path)
        
        cava_conf = f"""
[general]
bars = {self.bars}
[output]
method = raw
raw_target = {self.fifo_path}
bit_format = 8bit
[smoothing]
integral = 85
monstercat = 1
waves = 0
noise_reduction = 0.88
"""
        conf_path = "/tmp/cava_circular.conf"
        with open(conf_path, "w") as f:
            f.write(cava_conf)
            
        cava_bin = shutil.which("cava")
        if cava_bin:
            self.cava_exec = "/tmp/cava_circular_bin"
            shutil.copy2(cava_bin, self.cava_exec)
            os.chmod(self.cava_exec, 0o755)
        else:
            self.cava_exec = "cava"
            
        self.cava_proc = subprocess.Popen([self.cava_exec, "-p", conf_path], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def get_color_escape(self, ratio):
        if not self.colors:
            return "\033[0m"
        idx = int(ratio * (len(self.colors) - 1))
        hex_color = self.colors[idx].lstrip('#')
        r, g, b = tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))
        return f"\033[38;2;{r};{g};{b}m"

    def draw(self):
        with open(self.fifo_path, "rb") as fifo:
            print("\033[?25l", end="") # Hide cursor
            
            while self.running:
                data = fifo.read(self.bars)
                if not data:
                    break
                
                # Use local copies of dimensions for consistency in this frame
                w, h = self.canvas_width, self.canvas_height
                cx, cy = self.cx, self.cy
                
                # Grid now stores color ratios
                grid = [[None for _ in range(w)] for _ in range(h)]
                amplitudes = list(data)
                
                if self.mode == 'wave':
                    # ... (wave mode omitted for brevity or kept simple)
                    points = []
                    for i in range(self.bars):
                        angle = (i / self.bars) * 2 * math.pi
                        amp = amplitudes[i] / 255.0
                        # Reduced inner radius from radius*2 to radius*0.5
                        r = self.radius * 0.5 + amp * self.radius * 4
                        x = int(cx + r * math.cos(angle) * 2)
                        y = int(cy + r * math.sin(angle))
                        points.append((x, y))
                    for i in range(self.bars):
                        p1 = points[i]; p2 = points[(i + 1) % self.bars]
                        self.draw_line(grid, p1[0], p1[1], p2[0], p2[1], w, h, cx, cy)
                else: # bars mode
                    max_r = self.radius * 10 # For huge bars
                    for i in range(self.bars):
                        angle = (i / self.bars) * 2 * math.pi
                        amp = amplitudes[i] / 255.0
                        # Reduced inner radius from radius*1.2 to radius*0.4
                        inner_r = self.radius * 0.4
                        outer_r = inner_r + amp * self.radius * 8 # Increased to 8 for 'huge'
                        
                        for offset in [-0.02, -0.01, 0, 0.01, 0.02]: # 5 lines for 'huge' thickness
                            a = angle + offset
                            x_in = int(cx + inner_r * math.cos(a) * 2)
                            y_in = int(cy + inner_r * math.sin(a))
                            x_out = int(cx + outer_r * math.cos(a) * 2)
                            y_out = int(cy + outer_r * math.sin(a))
                            self.draw_line(grid, x_in, y_in, x_out, y_out, w, h, cx, cy)

                # Render grid to braille dots
                output = ["\033[H"]
                for y in range(0, h, 4):
                    row_str = ""
                    for x in range(0, w, 2):
                        braille_char = 0x2800
                        cell_colors = []
                        for dy in range(4):
                            for dx in range(2):
                                if y + dy < h and x + dx < w:
                                    val = grid[y+dy][x+dx]
                                    if val is not None:
                                        braille_char |= BRAILLE_DOTS[dy][dx]
                                        cell_colors.append(val)
                        
                        if braille_char == 0x2800:
                            row_str += " "
                        else:
                            # Average color ratio in this cell
                            avg_ratio = sum(cell_colors) / len(cell_colors)
                            color = self.get_color_escape(avg_ratio)
                            row_str += f"{color}{chr(braille_char)}"
                    output.append(row_str)
                
                sys.stdout.write("\n".join(output))
                sys.stdout.flush()

    def draw_line(self, grid, x0, y0, x1, y1, w, h, cx, cy):
        dx = abs(x1 - x0); dy = -abs(y1 - y0)
        sx = 1 if x0 < x1 else -1; sy = 1 if y0 < y1 else -1
        err = dx + dy
        
        while True:
            if 0 <= x0 < w and 0 <= y0 < h:
                # Calculate radial distance for gradient
                dist = math.sqrt(((x0 - cx)/2)**2 + (y0 - cy)**2)
                # Adjust max_expected to make the gradient more intense (transition faster)
                max_expected = self.radius * 6
                ratio = min(1.0, dist / max_expected)
                grid[y0][x0] = ratio
            if x0 == x1 and y0 == y1: break
            e2 = 2 * err
            if e2 >= dy: err += dy; x0 += sx
            if e2 <= dx: err += dx; y0 += sy

    def cleanup(self, signum=None, frame=None):
        self.running = False
        if self.cava_proc:
            self.cava_proc.terminate()
        if os.path.exists(self.fifo_path):
            os.remove(self.fifo_path)
        print("\033[?25h\033[0m")
        sys.exit(0)

if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--mode', choices=['wave', 'bars'], default='bars')
    parser.add_argument('--bars', type=int, default=36)
    parser.add_argument('--radius', type=int, default=10)
    parser.add_argument('colors', nargs='*', default=['#FF0000', '#FF8800', '#FFFF00'])
    args = parser.parse_args()
    
    vis = CircularCava(bars=args.bars, radius=args.radius, colors=args.colors if args.colors else None, mode=args.mode)
    signal.signal(signal.SIGINT, vis.cleanup)
    signal.signal(signal.SIGTERM, vis.cleanup)
    signal.signal(signal.SIGWINCH, vis.handle_resize)
    signal.signal(signal.SIGUSR1, vis.load_colors_from_state)
    
    try:
        vis.setup_cava()
        vis.draw()
    except Exception as e:
        vis.cleanup()
