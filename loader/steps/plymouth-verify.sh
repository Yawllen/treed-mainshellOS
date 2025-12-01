#!/bin/bash
set -euo pipefail

. "${REPO_DIR}/loader/lib/common.sh"

THEME_NAME="treed"
THEME_DIR="/usr/share/plymouth/themes/${THEME_NAME}"
CMDLINE="/boot/firmware/cmdline.txt"

log_info "plymouth-verify: enforce '${THEME_NAME}', initramfs, cmdline"

if [ ! -d "${THEME_DIR}" ]; then
  log_error "plymouth-verify: theme not found: ${THEME_DIR}"
  exit 1
fi

sudo plymouth-set-default-theme "${THEME_NAME}" -R

if [ -f "${CMDLINE}" ]; then
  CURRENT="$(cat "${CMDLINE}")"
  [[ "${CURRENT}" == *"quiet"* ]] || CURRENT="${CURRENT} quiet"
  [[ "${CURRENT}" == *"splash"* ]] || CURRENT="${CURRENT} splash"
  [[ "${CURRENT}" == *"plymouth.ignore-serial-consoles"* ]] || CURRENT="${CURRENT} plymouth.ignore-serial-consoles"
  printf "%s\n" "${CURRENT}" | sudo tee "${CMDLINE}" >/dev/null
  sync
else
  log_warn "plymouth-verify: ${CMDLINE} not found"
fi

# Доп. страховка: если пакет/ядро обновились — пересоберём initramfs ещё раз
if command -v update-initramfs >/dev/null 2>&1; then
  sudo update-initramfs -u
fi

log_info "plymouth-verify: OK"
