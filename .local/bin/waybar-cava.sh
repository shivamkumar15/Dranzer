#!/usr/bin/env bash
set -u

if ! command -v cava >/dev/null 2>&1; then
  echo "no-cava"
  exit 0
fi

bars=(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)
config_file="/tmp/waybar_cava_config"

cat > "$config_file" <<'EOF'
[general]
bars = 18
framerate = 24
autosens = 1

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

trap 'kill 0 2>/dev/null || true' EXIT
pause_start=0

convert_to_bars() {
  local line="$1"
  local IFS=';'
  local -a nums
  read -ra nums <<< "$line"
  local out=""
  local n

  for n in "${nums[@]}"; do
    if (( n < 0 || n > 7 )); then
      n=0
    fi
    out+="${bars[n]}"
  done

  printf '%s\n' "$out"
}

is_silence() {
  local l="${1//;/}"
  [[ -z "${l//0/}" ]]
}

cava -p "$config_file" 2>/dev/null | while IFS= read -r line || [[ -n "$line" ]]; do
  if is_silence "$line"; then
    if (( pause_start == 0 )); then
      pause_start=$SECONDS
    fi

    if (( SECONDS - pause_start >= 2 )); then
      printf '\n'
    else
      convert_to_bars "$line"
    fi
    continue
  fi

  pause_start=0
  convert_to_bars "$line"
done
