#!/bin/bash
set -euo pipefail

. "${REPO_DIR}/loader/lib/common.sh"
. "${REPO_DIR}/loader/lib/plymouth.sh"
. "${REPO_DIR}/loader/lib/rpi.sh"

ensure_root

if ! command -v plymouth-set-default-theme >/dev/null 2>&1; then
  log_warn "plymouth-initramfs: plymouth-set-default-theme not found; skipping step"
  exit 0
fi

BOOT_DIR="$(detect_boot_dir)"
CMDLINE_FILE="$(detect_cmdline_file "${BOOT_DIR}")"
CMDLINE_CONTENT="$(detect_cmdline_content "${CMDLINE_FILE}")"

log_info "plymouth-initramfs: boot_dir=${BOOT_DIR}, cmdline_file=${CMDLINE_FILE}"
log_info "plymouth-initramfs: current cmdline='${CMDLINE_CONTENT}'"

plymouth_set_default_theme
plymouth_rebuild_initramfs

log_info "plymouth-initramfs: OK"
