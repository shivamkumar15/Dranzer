#!/usr/bin/env python3
"""Shared BitBeast theme-color loader.

Reads the active theme from ``$XDG_CONFIG_HOME/bitbeast/current.conf`` (falling
back to the dranzer theme) and exposes the palette plus a few derived shades and
rgb triplets so every GTK popup stays in sync with the active BitBeast theme.

Import from any bitbeast-* popup with::

    from bitbeast_colors import load as load_bitbeast_colors
    c = load_bitbeast_colors()
    BG, PRIMARY, ACCENT, TEXT = c["bg"], c["primary"], c["accent"], c["text"]
"""

import os
import re

_FALLBACK = {
    "bg": "#150608",
    "primary": "#ff2d55",
    "secondary": "#2c0d0f",
    "accent": "#ffd166",
    "text": "#fff1dd",
}


def _hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip("#")
    return (int(hex_color[0:2], 16), int(hex_color[2:4], 16), int(hex_color[4:6], 16))


def _clamp8(value):
    return max(0, min(255, int(round(value))))


def _rgb_to_hex(r, g, b):
    return "#%02x%02x%02x" % (_clamp8(r), _clamp8(g), _clamp8(b))


def shade(hex_color, factor):
    """Multiply every channel by ``factor`` (>1 lighter, <1 darker)."""
    r, g, b = _hex_to_rgb(hex_color)
    return _rgb_to_hex(r * factor, g * factor, b * factor)


def mix(color_a, color_b, weight):
    """Linear blend (weight 0 -> a, 1 -> b)."""
    ar, ag, ab = _hex_to_rgb(color_a)
    br, bg_, bb = _hex_to_rgb(color_b)
    return _rgb_to_hex(
        ar + (br - ar) * weight,
        ag + (bg_ - ag) * weight,
        ab + (bb - ab) * weight,
    )


def rgba(hex_color, alpha):
    r, g, b = _hex_to_rgb(hex_color)
    return "rgba(%d, %d, %d, %s)" % (r, g, b, alpha)


def rgb_triplet(hex_color):
    r, g, b = _hex_to_rgb(hex_color)
    return "%d, %d, %d" % (r, g, b)


def load():
    """Return the active theme palette plus derived shades and rgb triplets."""
    colors = dict(_FALLBACK)

    config_home = os.environ.get("XDG_CONFIG_HOME", os.path.expanduser("~/.config"))
    current_conf = os.path.join(config_home, "bitbeast", "current.conf")
    if not os.path.isfile(current_conf):
        current_conf = os.path.join(config_home, "bitbeasts", "dranzer", "colors.conf")

    try:
        with open(current_conf, "r", encoding="utf-8", errors="ignore") as handle:
            for line in handle:
                match = re.match(r"\$(\w+)\s*=\s*rgb\(([0-9a-fA-F]{6})\)", line.strip())
                if match:
                    colors[match.group(1).lower()] = "#" + match.group(2).lower()
    except OSError:
        pass

    # Derived shades kept dark/neutral so backgrounds adapt to any theme
    # without forcing the (sometimes vivid) secondary color onto surfaces.
    colors["bg_alt"] = shade(colors["bg"], 1.7)
    colors["bg_panel"] = shade(colors["bg"], 1.3)
    colors["bg_card"] = shade(colors["bg"], 1.9)
    colors["bg_soft"] = shade(colors["bg"], 1.5)
    colors["bg_deep"] = shade(colors["bg"], 0.55)
    colors["primary_dark"] = shade(colors["primary"], 0.82)
    colors["primary_light"] = mix(colors["primary"], colors["text"], 0.3)

    colors["text_dim"] = rgba(colors["text"], "0.66")
    colors["text_dim55"] = rgba(colors["text"], "0.55")

    for key in ("bg", "bg_alt", "bg_panel", "bg_card", "bg_soft", "bg_deep",
                "primary", "primary_dark", "primary_light", "secondary",
                "accent", "text"):
        colors[key + "_rgb"] = rgb_triplet(colors[key])

    return colors
