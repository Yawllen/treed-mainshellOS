#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PI_USER="${PI_USER:-${SUDO_USER:-pi}}"
PI_HOME="$(getent passwd "$PI_USER" | cut -d: -f6)"
BOOT_DIR="/boot/firmware"
[ -d "$BOOT_DIR" ] || BOOT_DIR="/boot"
CMDLINE_FILE="${BOOT_DIR}/cmdline.txt"
CONFIG_TXT="${BOOT_DIR}/config.txt"
THEME_DST="/usr/share/plymouth/themes/treed"
if [ -d "${REPO_DIR}/plymouth/treed" ]; then
  THEME_SRC="${REPO_DIR}/plymouth/treed"
elif [ -d "${REPO_DIR}/plymouth/themes/treed" ]; then
  THEME_SRC="${REPO_DIR}/plymouth/themes/treed"
elif [ -d "${REPO_DIR}/plymouth/theme/treed" ]; then
  THEME_SRC="${REPO_DIR}/plymouth/theme/treed"
elif [ -d "${REPO_DIR}/theme/treed" ]; then
  THEME_SRC="${REPO_DIR}/theme/treed"
else
  THEME_SRC=""
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get -y install plymouth plymouth-themes plymouth-label initramfs-tools rsync

if [ -d "$THEME_SRC" ]; then
  mkdir -p "$THEME_DST"
  rsync -a --delete "$THEME_SRC"/ "$THEME_DST"/
fi

mkdir -p /etc/plymouth
if [ -f /etc/plymouth/plymouthd.conf ]; then
  sed -i -E 's/^Theme=.*/Theme=treed/' /etc/plymouth/plymouthd.conf || true
else
  printf "[Daemon]\nTheme=treed\n" > /etc/plymouth/plymouthd.conf
fi

plymouth-set-default-theme treed || true
plymouth-set-default-theme treed --rebuild || true
update-initramfs -u || update-initramfs -c -k "$(uname -r)"

KVER="$(uname -r)"
INITRD_NAME="initrd.img-${KVER}"
if [ ! -f "${BOOT_DIR}/${INITRD_NAME}" ]; then
  update-initramfs -c -k "${KVER}"
fi
grep -q "^initramfs ${INITRD_NAME} followkernel$" "${CONFIG_TXT}" 2>/dev/null || {
  sed -i "/^initramfs /d" "${CONFIG_TXT}" 2>/dev/null || true
  printf "initramfs %s followkernel\n" "${INITRD_NAME}" >> "${CONFIG_TXT}"
}

if ! grep -q "^gpu_mem=" "${CONFIG_TXT}" ; then
  printf "gpu_mem=128\n" >> "${CONFIG_TXT}"
else
  CUR_GPU_MEM="$(grep -E "^gpu_mem=" "${CONFIG_TXT}" | tail -n1 | cut -d= -f2)"
  case "${CUR_GPU_MEM}" in ''|*[!0-9]*) CUR_GPU_MEM=0;; esac
  if [ "${CUR_GPU_MEM:-0}" -lt 96 ]; then
    sed -i -E "s/^gpu_mem=.*/gpu_mem=128/" "${CONFIG_TXT}"
  fi
fi

LINE="$(tr -d '\n' < "${CMDLINE_FILE}")"
for tok in "plymouth.enable=0"; do
  LINE="$(printf "%s" "${LINE}" | sed -E "s/(^| )${tok}( |$)/ /g")"
done
need_add() { printf "%s" "$LINE" | grep -qE "(^| )$1( |$)"; }
add_tok() { need_add "$1" || LINE="${LINE} $1"; }
add_tok "quiet"
add_tok "splash"
add_tok "plymouth.ignore-serial-consoles"
add_tok "logo.nologo"
add_tok "vt.global_cursor_default=0"
LINE="$(echo "$LINE" | tr -s ' ')"
printf "%s\n" "${LINE# }" > "${CMDLINE_FILE}"

systemctl mask getty@tty1.service || true
systemctl mask plymouth-quit.service plymouth-quit-wait.service || true

mkdir -p /etc/systemd/system/KlipperScreen.service.d
cat > /etc/systemd/system/KlipperScreen.service.d/override.conf <<'EOF'
[Service]
ExecStartPre=/bin/sh -lc 'plymouth quit --retain-splash || true'
EOF

systemctl daemon-reload
