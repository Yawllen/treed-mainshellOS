#!/bin/bash
set -euo pipefail

. "${REPO_DIR}/loader/lib/common.sh"

ensure_root

STATE_DIR="/home/pi/treed/state/cmdline"
SCRIPTS_DIR="/home/pi/treed/scripts"

ensure_dir "$STATE_DIR"
ensure_dir "$SCRIPTS_DIR"

install -m 0755 "${REPO_DIR}/scripts/cmdline-guard.sh" "${SCRIPTS_DIR}/cmdline-guard.sh"
install -m 0644 "${REPO_DIR}/loader/systemd/treed-cmdline-guard.service" /etc/systemd/system/treed-cmdline-guard.service
install -m 0644 "${REPO_DIR}/loader/systemd/treed-cmdline-guard.path" /etc/systemd/system/treed-cmdline-guard.path
install -m 0644 "${REPO_DIR}/loader/systemd/treed-cmdline-guard-boot.service" /etc/systemd/system/treed-cmdline-guard-boot.service

systemctl daemon-reload

if [ ! -f "${STATE_DIR}/cmdline.expected" ]; then
  "${SCRIPTS_DIR}/cmdline-guard.sh" init || true
fi

systemctl enable --now treed-cmdline-guard.path
systemctl enable --now treed-cmdline-guard-boot.service

log_info "cmdline-guard: installed and enabled"
