#!/bin/bash
for f in /home/sniperxamster/Downloads/Dranzer/.config/bitbeasts/*/rofi.rasi; do
    # Replace background alpha completely to 7A (~48% opacity) for glass effect
    sed -i -E 's/(bg:[[:space:]]*#[0-9a-fA-F]{6})[0-9a-fA-F]{2};/\17a;/g' "$f"
    
    # Increase window border padding and radius for glass pill look
    sed -i 's/border-radius: 22px;/border-radius: 28px;/g' "$f"
    sed -i 's/padding: 22px;/padding: 32px;/g' "$f"
    
    # Detach and pill-ify inputbar
    sed -i 's/padding: 14px 18px;/padding: 18px 22px;/g' "$f"
    
    # Modify selected elements for better highlight contrast
    sed -i 's/element selected.normal {/element selected.normal { border: 1px; border-color: @primary; box-shadow: 0 4px 12px; /g' "$f"
    
done
