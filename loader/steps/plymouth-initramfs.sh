#!/bin/bash
set -euo pipefail

. "${REPO_DIR}/loader/lib/common.sh"

if ! command -v plymouth-set-default-theme >/dev/null 2>&1; then
  log_warn "plymouth-set-default-theme not found; skipping"
  exit 0
fi

log_info "Setting Plymouth theme and rebuilding initramfs (Raspberry Pi mode)"
sudo plymouth-set-default-theme treed -R

log_info "plymouth-initramfs: OK"
