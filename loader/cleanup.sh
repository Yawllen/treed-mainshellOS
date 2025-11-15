#!/bin/bash
set -euo pipefail

trap 'echo "[cleanup] error on line $LINENO" >&2' ERR

PI_USER="${PI_USER:-${SUDO_USER:-$(id -un)}}"
PI_HOME="$(getent passwd "$PI_USER" | cut -d: -f6 || echo "/home/${PI_USER}")"

if [ -f /boot/firmware/cmdline.txt ]; then
  BOOT_DIR="/boot/firmware"
elif [ -f /boot/cmdline.txt ]; then
  BOOT_DIR="/boot"
else
  BOOT_DIR=""
fi

CMDLINE_FILE=""
CONFIG_TXT=""

if [ -n "${BOOT_DIR}" ]; then
  CMDLINE_FILE="${BOOT_DIR}/cmdline.txt"
  CONFIG_TXT="${BOOT_DIR}/config.txt"
fi

echo "[cleanup] reset plymouth theme to text (safe default)"
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
  sudo plymouth-set-default-theme text || true
fi

if command -v update-initramfs >/dev/null 2>&1; then
  echo "[cleanup] updating initramfs"
  sudo update-initramfs -u || true
fi

if [ -n "${CONFIG_TXT}" ] && [ -f "${CONFIG_TXT}" ]; then
  echo "[cleanup] removing initramfs line added by loader (if any)"
  sudo sed -i '/^initramfs initrd.img-.* followkernel$/d' "${CONFIG_TXT}" || true
fi

if command -v systemctl >/dev/null 2>&1; then
  echo "[cleanup] unmasking services"
  sudo systemctl unmask getty@tty1.service || true
  sudo systemctl unmask plymouth-quit.service plymouth-quit-wait.service || true

  if [ -f /etc/systemd/system/KlipperScreen.service.d/override.conf ]; then
    echo "[cleanup] removing KlipperScreen override"
    sudo rm -f /etc/systemd/system/KlipperScreen.service.d/override.conf
    sudo systemctl daemon-reload || true
  fi
fi

echo "[cleanup] done. Reboot recommended."
