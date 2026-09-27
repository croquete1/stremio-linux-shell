#!/bin/bash
# run.sh NAME KIND(flatpak|source) DISP(x11|wayland) [VAR=VAL ...]
set -u
name=$1; kind=$2; disp=$3; shift 3
envs=("$@")
out=$PWD/out/$name; mkdir -p "$out"
here=$(cd "$(dirname "$0")" && pwd)
log() { echo "[$(date +%T)] $*" | tee -a "$out/steps.txt"; }

if [ "$disp" = x11 ]; then
  export DISPLAY=:99; unset WAYLAND_DISPLAY
  shot() { import -display :99 -window root "$out/$1.png" 2>/dev/null; box="0 50 1700 1050"; }
else
  export WAYLAND_DISPLAY=wayland-1; unset DISPLAY
  shot() { (cd "$out" && rm -f wayland-screenshot*.png && timeout 10 weston-screenshooter >/dev/null 2>&1; f=$(ls -t wayland-screenshot*.png 2>/dev/null | head -1); [ -n "$f" ] && mv "$f" "$1.png"); box="0 50 1920 1080"; }
fi
measure() { shot "$1"; if [ -f "$out/$1.png" ]; then m=$(python3 "$here/metric.py" "$out/$1.png" $box); else m="no-screenshot"; fi; log "shot $1 $m"; }

if [ "$kind" = mini ]; then
  fe=(); for e in "${envs[@]}"; do fe+=("--env=$e"); done
  cmd=(flatpak run --user --command=python3 --share=network --share=ipc --socket=wayland --socket=fallback-x11 --device=all --filesystem="$here":ro "${fe[@]}" org.gnome.Platform//50 "$here/mini.py")
elif [ "$kind" = flatpak ]; then
  fe=(); for e in "${envs[@]}"; do fe+=("--env=$e"); done
  cmd=(flatpak run --user "${fe[@]}" com.stremio.Stremio.Devel ${URL:+--url "$URL"})
else
  de=(); for e in "${envs[@]}"; do de+=(-e "$e"); done
  cmd=(docker run --rm --name "src-$name" --network host --ipc host --shm-size 1g --security-opt seccomp=unconfined --security-opt apparmor=unconfined
       -e DISPLAY -e WAYLAND_DISPLAY -e XDG_RUNTIME_DIR=/xdg -v /tmp/.X11-unix:/tmp/.X11-unix -v "$XDG_RUNTIME_DIR:/xdg"
       -e SERVER_PATH=/opt/stremio/server.js -e WEBKIT_DISABLE_SANDBOX_THIS_IS_DANGEROUS=1 -e RUST_LOG=debug -e GSETTINGS_SCHEMA_DIR=/opt/stremio/schemas
       "${de[@]}" -v "$PWD/srcbin:/opt/stremio" stremio-src dbus-run-session -- /opt/stremio/stremio-linux-shell ${URL:+--url "$URL"})
fi
log "run $name kind=$kind disp=$disp env=${envs[*]:-} url=${URL:-default}"
"${cmd[@]}" > "$out/app.log" 2>&1 &
app=$!
t0=$(date +%s)
at() { while [ $(( $(date +%s) - t0 )) -lt "$1" ]; do bash "$here/sample.sh" "$out/proc.txt"; sleep 1; done; }
at 2;  measure t02
at 5;  measure t05
at 30; measure t30
at 45; measure t45
if [ "$disp" = x11 ]; then
  xdotool mousemove 850 520; sleep 0.3; xdotool mousemove 900 560; sleep 1; measure pointer
  for i in 1 2 3; do xdotool click 5; sleep 0.2; done; sleep 1; measure scroll
  for i in 1 2 3; do xdotool click 4; sleep 0.2; done; sleep 1
  xdotool mousemove 330 360 click 1; sleep 5; measure title
  xdotool click 8; sleep 4; measure back
fi
at 75; measure t75
at 95
log "alive=$(kill -0 $app 2>/dev/null && echo yes || echo no)"
if [ "$kind" = mini ]; then pkill -f mini.py; elif [ "$kind" = source ]; then docker kill "src-$name" >/dev/null 2>&1; else flatpak kill com.stremio.Stremio.Devel 2>/dev/null; fi
kill $app 2>/dev/null; wait $app 2>/dev/null
python3 "$here/summary.py" "$out" | tee -a "$out/steps.txt"
