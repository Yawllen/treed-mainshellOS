#!/bin/bash
set -euo pipefail

. "${REPO_DIR}/loader/lib/common.sh"
. "${REPO_DIR}/loader/lib/plymouth.sh"

log_info "Step plymouth-cmdline: updating kernel cmdline for plymouth"

if [ -z "${CMDLINE_FILE:-}" ]; then
  if [ -f /boot/firmware/cmdline.txt ]; then
    CMDLINE_FILE=/boot/firmware/cmdline.txt
  elif [ -f /boot/cmdline.txt ]; then
    CMDLINE_FILE=/boot/cmdline.txt
  fi
fi

if [ -z "${CMDLINE_FILE:-}" ] || [ ! -f "${CMDLINE_FILE}" ]; then
  log_warn "plymouth-cmdline: CMDLINE_FILE not found, skipping"
  exit 0
fi

backup_file_once "${CMDLINE_FILE}"
normalize_cmdline "${CMDLINE_FILE}"

log_info "plymouth-cmdline: OK"
