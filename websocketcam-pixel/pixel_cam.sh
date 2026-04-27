#!/usr/bin/env bash
set -euo pipefail

URL="${PIXEL_CAM_URL:-ws://192.168.50.30:3535}"
DEV_NR="${PIXEL_CAM_VIDEO_NR:-10}"
DEV="/dev/video${DEV_NR}"
LABEL="${PIXEL_CAM_LABEL:-WebsocketCAM Pixel}"
WIDTH="${PIXEL_CAM_WIDTH:-800}"
HEIGHT="${PIXEL_CAM_HEIGHT:-600}"
FPS="${PIXEL_CAM_FPS:-30}"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<EOF
Usage: pixel_cam [options]

Starts Pixel WebsocketCAM -> v4l2loopback bridge.
It creates ${DEV} automatically if missing, then runs the Python bridge.

Options:
  --url URL             WebSocket URL [default: $URL]
  --device /dev/videoN  output v4l2 device [default: $DEV]
  --video-nr N          output v4l2 number [default: $DEV_NR]
  --width N             output width [default: $WIDTH]
  --height N            output height [default: $HEIGHT]
  --fps N               output fps [default: $FPS]
  --mirror              mirror image horizontally
  --reload-device       force reload v4l2loopback module
  --stop-device         unload v4l2loopback and exit
  --status              print camera/device status and exit
  -h, --help            show help

Env overrides:
  PIXEL_CAM_URL, PIXEL_CAM_VIDEO_NR, PIXEL_CAM_WIDTH, PIXEL_CAM_HEIGHT, PIXEL_CAM_FPS, PIXEL_CAM_LABEL
EOF
}

MIRROR=0
RELOAD=0
STOP=0
STATUS=0
EXTRA=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) URL="$2"; shift 2 ;;
    --device) DEV="$2"; DEV_NR="${2#/dev/video}"; shift 2 ;;
    --video-nr) DEV_NR="$2"; DEV="/dev/video${DEV_NR}"; shift 2 ;;
    --width) WIDTH="$2"; shift 2 ;;
    --height) HEIGHT="$2"; shift 2 ;;
    --fps) FPS="$2"; shift 2 ;;
    --mirror) MIRROR=1; shift ;;
    --reload-device) RELOAD=1; shift ;;
    --stop-device) STOP=1; shift ;;
    --status) STATUS=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) EXTRA+=("$1"); shift ;;
  esac
done

status() {
  echo "URL:     $URL"
  echo "Device:  $DEV"
  echo "Output:  ${WIDTH}x${HEIGHT}@${FPS}"
  echo
  echo "== processes =="
  pgrep -af 'websocketcam_to_v4l2|pixel_cam.sh' || true
  echo
  echo "== v4l2loopback =="
  lsmod | grep '^v4l2loopback\b' || echo 'not loaded'
  echo
  echo "== video devices =="
  ls -l /dev/video* 2>/dev/null || echo 'none'
  echo
  echo "== v4l2 devices =="
  v4l2-ctl --list-devices 2>/dev/null || true
  echo
  echo "== route/port to phone =="
  ip route get "$(echo "$URL" | sed -E 's#^ws://([^/:]+).*#\1#')" 2>/dev/null || true
  timeout 2 bash -lc "</dev/tcp/$(echo "$URL" | sed -E 's#^ws://([^/:]+).*#\1#')/$(echo "$URL" | sed -E 's#^ws://[^/:]+:([0-9]+).*#\1#')" \
    && echo 'phone port: OPEN' || echo 'phone port: CLOSED/FAIL'
}

if [[ "$STATUS" == 1 ]]; then
  status
  exit 0
fi

if [[ "$STOP" == 1 ]]; then
  echo "Stopping bridge processes and unloading v4l2loopback..."
  pkill -f "websocketcam_to_v4l2.py.*${DEV}" 2>/dev/null || true
  sudo modprobe -r v4l2loopback || true
  exit 0
fi

if [[ ! -x "$SCRIPT_DIR/websocketcam_to_v4l2.py" ]]; then
  echo "ERROR: bridge script missing: $SCRIPT_DIR/websocketcam_to_v4l2.py" >&2
  exit 1
fi
if [[ ! -d "$SCRIPT_DIR/.venv" ]]; then
  echo "ERROR: venv missing: $SCRIPT_DIR/.venv" >&2
  exit 1
fi
if ! modinfo v4l2loopback >/dev/null 2>&1; then
  echo "ERROR: v4l2loopback module not installed. Install: sudo apt install v4l2loopback-dkms" >&2
  exit 1
fi

if [[ "$RELOAD" == 1 ]]; then
  echo "Reloading v4l2loopback..."
  sudo modprobe -r v4l2loopback 2>/dev/null || true
fi

if [[ ! -e "$DEV" ]]; then
  echo "$DEV does not exist; loading v4l2loopback..."
  if lsmod | grep -q '^v4l2loopback\b'; then
    echo "v4l2loopback is loaded but $DEV is missing; reloading module."
    sudo modprobe -r v4l2loopback 2>/dev/null || true
  fi
  sudo modprobe v4l2loopback video_nr="$DEV_NR" card_label="$LABEL" exclusive_caps=1
fi

if [[ ! -w "$DEV" ]]; then
  echo "WARNING: $DEV is not writable by current user. Check group 'video' or re-login." >&2
  ls -l "$DEV" >&2 || true
fi

echo "Using $DEV:"
v4l2-ctl --list-devices 2>/dev/null | sed -n "/${LABEL}/,+2p" || ls -l "$DEV"
echo

echo "Starting bridge: $URL -> $DEV (${WIDTH}x${HEIGHT}@${FPS})"
echo "Keep this terminal open. Ctrl+C stops camera feed."
cd "$SCRIPT_DIR"
# shellcheck disable=SC1091
. .venv/bin/activate
CMD=("$SCRIPT_DIR/websocketcam_to_v4l2.py" "$URL" --device "$DEV" --width "$WIDTH" --height "$HEIGHT" --fps "$FPS")
if [[ "$MIRROR" == 1 ]]; then CMD+=(--mirror); fi
CMD+=("${EXTRA[@]}")
exec "${CMD[@]}"
