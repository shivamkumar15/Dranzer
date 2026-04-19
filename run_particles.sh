#!/bin/bash
# Particle Visualizer Launcher
# Run this to start the particle simulator with CAVA

# Create FIFO if it doesn't exist
FIFO_PATH="$HOME/.config/cava/fifo"
mkdir -p "$(dirname "$FIFO_PATH")"

if [ ! -p "$FIFO_PATH" ]; then
    mkfifo "$FIFO_PATH"
fi

# Run CAVA in background using the active BitBeast config.
# The config writes ASCII data directly into the FIFO.
cava -p "$HOME/.config/cava/config" >/dev/null 2>&1 &
CAVA_PID=$!

# Run particle visualizer
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/particle_visualizer_advanced.py" --mode terminal

# Cleanup on exit
kill $CAVA_PID 2>/dev/null
