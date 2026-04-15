#!/bin/bash
set -euo pipefail

STATE_DIR=/var/lib/firstboot-grow-root
STAGE1_DONE="$STATE_DIR/stage1_done"
SERVICE=firstboot-grow-root.service
DEV=/dev/mmcblk0
PART=${DEV}p2

mkdir -p "$STATE_DIR"

part_size_bytes() {
  blockdev --getsize64 "$PART"
}

fs_size_bytes() {
  dumpe2fs -h "$PART" 2>/dev/null | awk -F": " '
    /Block count:/ {bc=$2}
    /Block size:/ {bs=$2}
    END {if (bc && bs) print bc*bs; else print 0}'
}

disable_service() {
  systemctl disable "$SERVICE" || true
  rm -f /etc/systemd/system/multi-user.target.wants/"$SERVICE"
}

grow_partition() {
  echo ", +" | sfdisk --force --no-reread -N 2 "$DEV"
}

if [ ! -e "$STAGE1_DONE" ]; then
  grow_partition
  partprobe "$DEV" || true
  blockdev --rereadpt "$DEV" || true
  partx -u "$DEV" || true
  udevadm settle || true

  touch "$STAGE1_DONE"

  new_part_size=$(part_size_bytes)
  fs_size=$(fs_size_bytes)

  if [ "$new_part_size" -gt "$fs_size" ]; then
    resize2fs "$PART"
    disable_service
    rm -f "$STAGE1_DONE"
    exit 0
  fi

  sync
  reboot
  exit 0
fi

resize2fs "$PART"
disable_service
rm -f "$STAGE1_DONE"
