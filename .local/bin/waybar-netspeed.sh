#!/usr/bin/env bash
set -u

pick_iface() {
  local iface
  iface=$(awk '$2 == "00000000" {print $1; exit}' /proc/net/route 2>/dev/null)
  if [[ -n "$iface" && -d "/sys/class/net/$iface" ]]; then
    printf '%s\n' "$iface"
    return
  fi

  for iface in /sys/class/net/*; do
    iface=${iface##*/}
    [[ "$iface" == "lo" ]] && continue
    if [[ -d "/sys/class/net/$iface" ]]; then
      printf '%s\n' "$iface"
      return
    fi
  done
}

format_rate() {
  local bytes_per_sec=$1
  if (( bytes_per_sec < 1024 )); then
    printf '%dB/s' "$bytes_per_sec"
  elif (( bytes_per_sec < 1048576 )); then
    printf '%.1fK/s' "$(awk -v n="$bytes_per_sec" 'BEGIN{print n/1024}')"
  else
    printf '%.1fM/s' "$(awk -v n="$bytes_per_sec" 'BEGIN{print n/1048576}')"
  fi
}

iface=$(pick_iface)
if [[ -z "$iface" ]]; then
  echo "󰤮 --"
  exit 0
fi

rx_file="/sys/class/net/$iface/statistics/rx_bytes"
tx_file="/sys/class/net/$iface/statistics/tx_bytes"

if [[ ! -r "$rx_file" || ! -r "$tx_file" ]]; then
  echo "󰤮 --"
  exit 0
fi

prev_rx=$(<"$rx_file")
prev_tx=$(<"$tx_file")
prev_ts=$(date +%s)

while true; do
  sleep 1

  now_rx=$(<"$rx_file")
  now_tx=$(<"$tx_file")
  now_ts=$(date +%s)
  dt=$(( now_ts - prev_ts ))
  (( dt <= 0 )) && dt=1

  drx=$(( now_rx - prev_rx ))
  dtx=$(( now_tx - prev_tx ))
  (( drx < 0 )) && drx=0
  (( dtx < 0 )) && dtx=0

  down=$(format_rate $(( drx / dt )))
  up=$(format_rate $(( dtx / dt )))

  printf '󰇚 %s 󰕒 %s\n' "$down" "$up"

  prev_rx=$now_rx
  prev_tx=$now_tx
  prev_ts=$now_ts
done
