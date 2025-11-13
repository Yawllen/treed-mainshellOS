#!/bin/bash
set -euo pipefail

PROFILE_NAME="${1:-rn12_hbot_v1}"

BASE_DIR="/home/pi/treed/klipper"
PROFILES_DIR="${BASE_DIR}/profiles"
PROFILE_DIR="${PROFILES_DIR}/${PROFILE_NAME}"
CURRENT_LINK="${PROFILES_DIR}/current"
CONFIG_DIR="/home/pi/printer_data/config"
PRINTER_CFG="${CONFIG_DIR}/printer.cfg"

mkdir -p "${PROFILE_DIR}"

SERIAL_PATH="$(ls /dev/serial/by-id/* 2>/dev/null | head -n 1 || true)"

mkdir -p "${BASE_DIR}"

cat > "${BASE_DIR}/printer_root.cfg" <<EOF_ROOT
[include profiles/current/root.cfg]
EOF_ROOT

cat > "${PROFILE_DIR}/root.cfg" <<EOF_PROFILE
[mcu]
serial: ${SERIAL_PATH}
restart_method: command

[printer]
kinematics: none
max_velocity: 200
max_accel: 2000
square_corner_velocity: 5.0
EOF_PROFILE

ln -sfn "${PROFILE_NAME}" "${CURRENT_LINK}"

mkdir -p "${CONFIG_DIR}"

if [ -f "${PRINTER_CFG}" ] && [ ! -L "${PRINTER_CFG}" ]; then
  cp "${PRINTER_CFG}" "${PRINTER_CFG}.bak.$(date +%Y%m%d%H%M%S)"
fi

cat > "${PRINTER_CFG}" <<EOF_PRC
[include ${BASE_DIR}/printer_root.cfg]
EOF_PRC

sudo systemctl restart klipper
