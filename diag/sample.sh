#!/bin/bash
# sample.sh OUT: one snapshot of shell/WebKit processes (state, cpu, rss, fds, cumulative cpu ticks)
out=$1
{
  echo "## t=$(date +%s)"
  for pid in $(pgrep -f 'stremio-linux-shell|libexec/stremio/stremio|WebKitWebProcess|WebKitNetworkProcess|WebKitGPUProcess' ); do
    [ -r /proc/$pid/stat ] || continue
    comm=$(cat /proc/$pid/comm 2>/dev/null)
    case "$comm" in bwrap|sh|bash|flatpak*|docker*|timeout|dbus*) continue;; esac
    read -r st ut sy <<<"$(awk '{print $3, $14, $15}' /proc/$pid/stat)"
    rss=$(awk '/VmRSS/{print $2}' /proc/$pid/status)
    fds=$(sudo ls /proc/$pid/fd 2>/dev/null | wc -l)
    echo "pid=$pid comm=$comm state=$st ticks=$((ut+sy)) rss_kb=$rss fds=$fds"
  done
} >> "$out"
