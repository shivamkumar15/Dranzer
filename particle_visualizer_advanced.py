#!/usr/bin/env python3
"""
Advanced Particle Visualizer with Multiple Rendering Modes
- Terminal mode (curses)
- Swaybar/Waybar mode
- Raw frame output mode
"""

import os
import sys
import time
import math
import random
import threading
import argparse
from collections import deque
from dataclasses import dataclass

# Theme configurations per beast
THEMES = {
    'dranzer': {
        'colors': ['#440000', '#990000', '#FF0000', '#FF4400', '#FF8800', '#FFAA00', '#FFCC00', '#FFEE00'],
        'bg': '#0a0a0a'
    },
    'burningcerbrus': {
        'colors': ['#220033', '#440066', '#8800AA', '#AA00FF', '#FF00FF', '#FF44AA', '#FF8844', '#FFCC00'],
        'bg': '#0a0015'
    },
    'driger': {
        'colors': ['#002200', '#004400', '#008800', '#00FF00', '#44FF00', '#88FF00', '#CCFF00', '#FFFF00'],
        'bg': '#001100'
    },
    'dragoon': {
        'colors': ['#000044', '#000088', '#0000FF', '#0044FF', '#0088FF', '#00CCFF', '#00FFFF', '#AAFFFF'],
        'bg': '#000022'
    },
    'draciel': {
        'colors': ['#001122', '#002244', '#004488', '#0088FF', '#00FFFF', '#88FFFF', '#CCAAFF', '#FFEEFF'],
        'bg': '#000811'
    },
    'galeon': {
        'colors': ['#110022', '#220044', '#440088', '#8800FF', '#CC00FF', '#FF00FF', '#FFBB00', '#FFFF77'],
        'bg': '#080011'
    }
}

@dataclass
class Particle:
    x: float
    y: float
    vx: float
    vy: float
    color: str
    size: float
    life: int
    max_life: int
    trail: deque
    
    @staticmethod
    def create(x, y, color, size, life):
        vx = (random.random() - 0.5) * 4
        vy = -random.random() * 6 - 2
        return Particle(x, y, vx, vy, color, size, life, life, deque(maxlen=12))

class ParticleSystem:
    def __init__(self, theme='dranzer', max_particles=600, width=120, height=40):
        self.theme = THEMES.get(theme, THEMES['dranzer'])
        self.colors = self.theme['colors']
        self.max_particles = max_particles
        self.width = width
        self.height = height
        self.particles = []
        self.audio_data = [0] * 64
        self.smoothed_data = [0] * 64
        self.running = True
        self.frame_count = 0
        
        # Physics constants
        self.gravity = 0.12
        self.damping = 0.97
        self.sensitivity = 2.0
        
    def read_fifo(self, fifo_path):
        """Read from CAVA FIFO"""
        try:
            if os.path.exists(fifo_path):
                with open(fifo_path, 'r') as f:
                    while self.running:
                        line = f.readline()
                        if line:
                            data = line.strip().split(',')
                            if len(data) >= 64:
                                self.audio_data = [int(x) for x in data[:64]]
        except Exception as e:
            pass
            
    def smooth_audio(self):
        """Smooth audio data"""
        for i in range(64):
            self.smoothed_data[i] = self.smoothed_data[i] * 0.7 + self.audio_data[i] * 0.3
            
    def get_frequency_bands(self):
        """Get bass, mid, treble levels"""
        bass = sum(self.smoothed_data[:8]) / 8
        mid = sum(self.smoothed_data[8:32]) / 24
        treble = sum(self.smoothed_data[32:]) / 32
        return bass, mid, treble
        
    def spawn_particles(self):
        """Spawn particles based on audio"""
        bass, mid, treble = self.get_frequency_bands()
        
        # Spawn rate
        intensity = (bass + mid + treble) / 300
        spawn_count = int(intensity * 15)
        spawn_count = min(spawn_count, 25)
        
        center_x = self.width // 2
        center_y = self.height // 2
        
        for _ in range(spawn_count):
            if len(self.particles) >= self.max_particles:
                break
                
            # Frequency-based spawning
            freq_idx = random.choices(
                range(64), 
                weights=[max(0, self.smoothed_data[i]) for i in range(64)]
            )[0] if sum(self.smoothed_data) > 0 else random.randint(0, 63)
            
            color_idx = min(freq_idx // 8, len(self.colors) - 1)
            color = self.colors[color_idx]
            
            # Position from center with audio influence
            angle = (freq_idx / 64) * 2 * math.pi
            radius = 5 + (self.smoothed_data[freq_idx] / 100) * 20
            
            x = center_x + math.cos(angle) * radius
            y = center_y + math.sin(angle) * radius
            
            # Add some randomness
            x += random.uniform(-3, 3)
            y += random.uniform(-3, 3)
            
            size = 1 + (treble / 200) + random.random()
            life = 40 + int(bass / 10)
            
            self.particles.append(Particle.create(x, y, color, size, life))
            
    def update_particles(self):
        """Update all particles"""
        bass, mid, treble = self.get_frequency_bands()
        avg_level = (bass + mid + treble) / 300
        
        for p in self.particles:
            # Store trail
            p.trail.append((int(p.x), int(p.y)))
            
            # Audio influence
            p.vy -= avg_level * self.sensitivity * 0.08
            p.vx += (random.random() - 0.5) * bass * 0.02
            
            # Gravity
            p.vy += self.gravity
            
            # Damping
            p.vx *= self.damping
            p.vy *= self.damping
            
            # Update position
            p.x += p.vx
            p.y += p.vy
            
            # Life decay
            p.life -= 1
            
            # Size pulsation
            p.size = max(0.5, p.size + avg_level * 0.2)
            
        # Remove dead particles
        self.particles = [p for p in self.particles 
                         if 0 < p.life < 200 
                         and -10 < p.y < self.height + 10
                         and -10 < p.x < self.width + 10]
                         
    def update(self):
        """Main update"""
        self.smooth_audio()
        self.spawn_particles()
        self.update_particles()
        self.frame_count += 1
        
    def render_terminal(self):
        """Render for terminal (ASCII art)"""
        # Create buffer
        buffer = [[' ' for _ in range(self.width)] for _ in range(self.height)]
        
        # Draw particles (back to front for depth)
        sorted_particles = sorted(self.particles, key=lambda p: p.life)
        
        for p in sorted_particles:
            px, py = int(p.x), int(p.y)
            if 0 <= px < self.width and 0 <= py < self.height:
                alpha = p.life / p.max_life
                char = '●' if p.size > 1.5 else '•'
                buffer[py][px] = char
                
        # Draw trails
        for p in self.particles:
            for tx, ty in p.trail:
                if 0 <= tx < self.width and 0 <= ty < self.height:
                    buffer[ty][tx] = '·'
                    
        # Add frequency bars at bottom
        bar_width = self.width // 64
        for i in range(64):
            bar_height = int(self.smoothed_data[i] / 100 * (self.height // 3))
            color_idx = min(i // 8, len(self.colors) - 1)
            for j in range(min(bar_height, self.height - 3)):
                if self.height - 3 - j >= 0:
                    buffer[self.height - 3 - j][i * bar_width] = '█'
                    
        return '\n'.join(''.join(row) for row in buffer)
        
    def render_json(self):
        """Render as JSON for external renderers"""
        import json
        return json.dumps({
            'particles': [
                {
                    'x': p.x,
                    'y': p.y,
                    'vx': p.vx,
                    'vy': p.vy,
                    'color': p.color,
                    'size': p.size,
                    'life': p.life / p.max_life,
                    'trail': list(p.trail)
                }
                for p in self.particles
            ],
            'audio': self.smoothed_data,
            'theme': self.theme
        })
        
    def render_swaybar(self):
        """Render for swaybar"""
        bars = []
        for i in range(32):
            level = int(self.smoothed_data[i*2] / 100 * 10)
            bars.append('▁' * level)
        return ' '.join(bars)

def main():
    parser = argparse.ArgumentParser(description='Particle Visualizer')
    parser.add_argument('--theme', '-t', default='dranzer', 
                       choices=list(THEMES.keys()), help='Theme to use')
    parser.add_argument('--fifo', '-f', default='~/.config/cava/fifo',
                       help='CAVA FIFO path')
    parser.add_argument('--mode', '-m', default='terminal',
                       choices=['terminal', 'json', 'swaybar'],
                       help='Output mode')
    parser.add_argument('--width', '-w', type=int, default=120, help='Width')
    parser.add_argument('--height', '-H', type=int, default=40, help='Height')
    args = parser.parse_args()
    
    fifo_path = os.path.expanduser(args.fifo)
    system = ParticleSystem(args.theme, width=args.width, height=args.height)
    
    # Start FIFO reader
    reader = threading.Thread(target=system.read_fifo, args=(fifo_path,), daemon=True)
    reader.start()
    
    # Main loop
    try:
        while system.running:
            system.update()
            
            if args.mode == 'terminal':
                # Clear screen and render
                print('\033[2J\033[H', end='')  # Clear and home
                print(system.render_terminal())
            elif args.mode == 'json':
                print(system.render_json())
            elif args.mode == 'swaybar':
                print(system.render_swaybar())
                
            time.sleep(1/30)  # 30 FPS
            
    except KeyboardInterrupt:
        system.running = False

if __name__ == '__main__':
    main()