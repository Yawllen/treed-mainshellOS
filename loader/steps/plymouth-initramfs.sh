#!/bin/bash
set -euo pipefail

. "${REPO_DIR}/loader/lib/common.sh"
. "${REPO_DIR}/loader/lib/rpi.sh"
. "${REPO_DIR}/loader/lib/plymouth.sh"

log_info "Step plymouth-initramfs: ensuring initramfs and auto_initramfs"

if [ -z "${CONFIG_FILE:-}" ]; then
  if [ -f /boot/firmware/config.txt ]; then
    CONFIG_FILE=/boot/firmware/config.txt
  elif [ -f /boot/config.txt ]; then
    CONFIG_FILE=/boot/config.txt
  else
    log_error "CONFIG_FILE is not set and no config.txt found in /boot or /boot/firmware"
    exit 1
  fi
fi

backup_file_once "${CONFIG_FILE}"

if grep -q '^auto_initramfs=' "${CONFIG_FILE}" 2>/dev/null; then
  sed -i 's/^auto_initramfs=.*/auto_initramfs=1/' "${CONFIG_FILE}"
  log_info "Updated auto_initramfs=1 in ${CONFIG_FILE}"
else
  echo "auto_initramfs=1" >> "${CONFIG_FILE}"
  log_info "Added auto_initramfs=1 to ${CONFIG_FILE}"
fi

plymouth_set_default_theme
plymouth_rebuild_initramfs

log_info "plymouth-initramfs: OK"
