#!/bin/bash
set -euo pipefail

. "${REPO_DIR}/loader/lib/common.sh"

ensure_root

log_info "Step klipperscreen-install: installing KlipperScreen"

if ! command -v git >/dev/null 2>&1; then
  apt-get update
  apt-get -y install git
fi

if systemctl list-unit-files | grep -q '^KlipperScreen.service'; then
  log_info "KlipperScreen service already present, skipping installation"
else
  KS_STAGING_DIR="${PI_HOME}/treed/.staging/KlipperScreen"
  rm -rf "${KS_STAGING_DIR}"
  git clone --depth 1 https://github.com/jordanruthe/KlipperScreen.git "${KS_STAGING_DIR}"
  bash "${KS_STAGING_DIR}/scripts/KlipperScreen-install.sh"
  systemctl enable --now KlipperScreen.service || true
fi

log_info "klipperscreen-install: OK"
