#!/bin/bash
set -euo pipefail

. "${REPO_DIR}/loader/lib/common.sh"

KLIPPER_STAGE_DIR="${PI_HOME}/treed/klipper"
CONFIG_ROOT="${PI_HOME}/printer_data/config"
TARGET_DIR="${CONFIG_ROOT}/treed"

log_info "Step klipper-sync-to-config: syncing ${KLIPPER_STAGE_DIR} -> ${TARGET_DIR}"

if [ ! -d "${KLIPPER_STAGE_DIR}" ]; then
  log_warn "klipper-sync-to-config: source dir ${KLIPPER_STAGE_DIR} not found, skipping"
  exit 0
fi

ensure_dir "${CONFIG_ROOT}"

rm -rf "${TARGET_DIR}"
mkdir -p "${TARGET_DIR}"

cp -a "${KLIPPER_STAGE_DIR}/." "${TARGET_DIR}/"

# В runtime нам не нужен второй printer.cfg внутри treed,
# чтобы не путать с корневым /config/printer.cfg
rm -f "${TARGET_DIR}/printer.cfg"

chown -R "${PI_USER}:${PI_USER}" "${TARGET_DIR}"

log_info "klipper-sync-to-config: OK"
