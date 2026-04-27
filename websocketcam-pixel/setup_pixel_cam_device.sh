#!/usr/bin/env bash
set -euo pipefail

DEV_NR="${1:-10}"
LABEL="${2:-WebsocketCAM Pixel}"

echo "Loading v4l2loopback as /dev/video${DEV_NR} (${LABEL})"
if lsmod | grep -q '^v4l2loopback\b'; then
  if [ -e "/dev/video${DEV_NR}" ]; then
    echo "/dev/video${DEV_NR} already exists"
  else
    echo "v4l2loopback already loaded, but /dev/video${DEV_NR} does not exist. Reloading module."
    sudo modprobe -r v4l2loopback || true
    sudo modprobe v4l2loopback video_nr="${DEV_NR}" card_label="${LABEL}" exclusive_caps=1
  fi
else
  sudo modprobe v4l2loopback video_nr="${DEV_NR}" card_label="${LABEL}" exclusive_caps=1
fi

ls -l "/dev/video${DEV_NR}"
v4l2-ctl --list-devices 2>/dev/null || true
