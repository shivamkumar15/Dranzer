#!/usr/bin/env python3
"""
Particle Visualizer - CAVA Compatible
Creates a stunning particle simulation that reacts to audio frequencies
"""

import os
import sys
import time
import math
import random
import threading
import re
import numpy as np
from collections import deque

# Configuration
FIFO_PATH = os.path.expanduser("~/.config/cava/fifo")
BAR_COUNT = 64
MAX_PARTICLES = 500
GRAVITY = 0.15
DAMPING = 0.98
SENSITIVITY = 2.5

# Theme colors (Dranzer default)
THEME_COLORS = [
    '#440000', '#990000', '#FF0000', '#FF4400', 
    '#FF8800', '#FFAA00', '#FFCC00', '#FFEE00'
]

class Particle:
    def __init__(self, x, y, vx, vy, color, size, life):
        self.x = x
        self.y = y
        self.vx = vx
        self.vy = vy
        self.color = color
        self.size = size
        self.life = life
        self.max_life = life
        self.trail = deque(maxlen=8)
        
    def update(self, audio_level, bass_boost):
        # Store trail position
        self.trail.append((self.x, self.y))
        
        # Apply audio influence
        self.vy -= audio_level * SENSITIVITY * 0.1
        self.vx += (random.random() - 0.5) * bass_boost * 0.5
        
        # Apply gravity
        self.vy += GRAVITY
        
        # Apply damping
        self.vx *= DAMPING
        self.vy *= DAMPING
        
        # Update position
        self.x += self.vx
        self.y += self.vy
        
        # Decay life
        self.life -= 1
        
        # Size pulsation with audio
        self.size = max(1, self.size + audio_level * 0.3)
        
    def is_alive(self):
        return self.life > 0 and -500 < self.y < 1500
    
    def draw(self):
        alpha = self.life / self.max_life
        return f"circle {self.x:.0f} {self.y:.0f} {self.size:.1f} {self.color} {alpha:.2f}"

class ParticleSimulator:
    def __init__(self, width=1920, height=1080):
        self.width = width
        self.height = height
        self.particles = []
        self.audio_data = [0] * BAR_COUNT
        self.smoothed_data = [0] * BAR_COUNT
        self.running = True
        self.frame_count = 0
        
    def read_cava_data(self):
        """Read audio data from CAVA FIFO pipe"""
        try:
            if os.path.exists(FIFO_PATH):
                with open(FIFO_PATH, 'r') as f:
                    while self.running:
                        line = f.readline()
                        if line:
                            data = [value for value in re.split(r'[^0-9]+', line.strip()) if value]
                            if len(data) >= BAR_COUNT:
                                self.audio_data = [int(x) for x in data[:BAR_COUNT]]
        except Exception as e:
            print(f"Error reading CAVA: {e}", file=sys.stderr)
            
    def smooth_audio(self):
        """Apply smoothing to audio data"""
        smoothing = 0.3
        for i in range(BAR_COUNT):
            self.smoothed_data[i] = (
                self.smoothed_data[i] * (1 - smoothing) + 
                self.audio_data[i] * smoothing
            )
            
    def spawn_particles(self):
        """Spawn particles based on audio frequencies"""
        bass = sum(self.smoothed_data[:8]) / 8
        mid = sum(self.smoothed_data[8:32]) / 24
        treble = sum(self.smoothed_data[32:]) / 32
        
        # Spawn rate based on audio intensity
        spawn_rate = int(bass * 0.5 + mid * 0.3 + treble * 0.2)
        spawn_rate = min(spawn_rate, 20)
        
        center_x = self.width // 2
        center_y = self.height // 2
        
        for _ in range(spawn_rate):
            if len(self.particles) < MAX_PARTICLES:
                # Choose color based on frequency
                freq_idx = random.randint(0, BAR_COUNT-1)
                color_idx = int(freq_idx / BAR_COUNT * (len(THEME_COLORS) - 1))
                color = THEME_COLORS[color_idx]
                
                # Spawn position based on frequency
                angle = (freq_idx / BAR_COUNT) * 2 * math.pi
                radius = 100 + self.smoothed_data[freq_idx] * 2
                
                x = center_x + math.cos(angle) * radius
                y = center_y + math.sin(angle) * radius
                
                # Velocity based on audio
                vx = (random.random() - 0.5) * (5 + bass * 0.2)
                vy = -random.random() * (5 + mid * 0.3)
                
                size = 2 + random.random() * 3 + treble * 0.1
                life = 60 + int(bass * 0.5)
                
                self.particles.append(Particle(x, y, vx, vy, color, size, life))
                
    def update(self):
        """Update all particles"""
        self.smooth_audio()
        self.spawn_particles()
        
        bass = sum(self.smoothed_data[:8]) / 8
        mid = sum(self.smoothed_data[8:32]) / 24
        treble = sum(self.smoothed_data[32:]) / 32
        
        avg_level = (bass + mid + treble) / 3 / 100
        
        # Update particles
        for p in self.particles:
            p.update(avg_level, bass / 100)
            
        # Remove dead particles
        self.particles = [p for p in self.particles if p.is_alive()]
        self.frame_count += 1
        
    def render(self):
        """Render particles to stdout (for terminal output)"""
        output = []
        
        # Draw particles
        for p in self.particles:
            output.append(p.draw())
            
        return '\n'.join(output)
    
    def render_swaybar(self):
        """Render for swaybar/waybar"""
        output = []
        
        # Create frequency bars representation
        bars = []
        for i in range(BAR_COUNT):
            height = int(self.smoothed_data[i] / 100 * 20)
            bars.append('#' * height)
            
        return '|'.join(bars)
    
    def run(self):
        """Main loop"""
        # Start CAVA reader in background
        reader_thread = threading.Thread(target=self.read_cava_data, daemon=True)
        reader_thread.start()
        
        while self.running:
            self.update()
            output = self.render()
            print(output, flush=True)
            time.sleep(1/60)  # 60 FPS
            
    def stop(self):
        self.running = False

def main():
    simulator = ParticleSimulator()
    
    # Handle signals
    def signal_handler(sig, frame):
        simulator.stop()
        sys.exit(0)
        
    import signal
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    simulator.run()

if __name__ == "__main__":
    main()
