#!/bin/zsh

if [ -f "$HOME/.zsh/bitbeast-prompt.zsh" ]; then
    source "$HOME/.zsh/bitbeast-prompt.zsh"
elif [ -f "$HOME/.config/bitbeast/current.conf" ]; then
    source "$HOME/.config/bitbeast/current.conf" 2>/dev/null || true
fi

if [ -n "${BITBEAST_PRIMARY:-}" ]; then
    PRIMARY_COLOR="${BITBEAST_PRIMARY}"
    ACCENT_COLOR="${BITBEAST_ACCENT}"
    TEXT_COLOR="${BITBEAST_TEXT}"
    BG_COLOR="${BITBEAST_BG}"
else
    PRIMARY_COLOR="red"
    ACCENT_COLOR="yellow"
    TEXT_COLOR="white"
    BG_COLOR="black"
fi

PS1="%F{$PRIMARY_COLOR}%n%f%F{$TEXT_COLOR}@%f%F{$ACCENT_COLOR}%m%f %F{$TEXT_COLOR}%~%f %B%(3L|+)%b%f "
RPROMPT="%F{$PRIMARY_COLOR}%(?::%F{green}✓%f::%F{red}✗%f)%f"