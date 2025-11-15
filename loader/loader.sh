#!/bin/bash
set -euo pipefail
trap 'echo "[loader] error on line $LINENO"; exit 1' ERR

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PI_USER="${PI_USER:-${SUDO_USER:-pi}}"
PI_HOME="$(getent passwd "$PI_USER" | cut -d: -f6)"
if [ -z "${PI_HOME}" ] || [ ! -d "${PI_HOME}" ]; then
  echo "[loader] ERROR: cannot determine home for user ${PI_USER}"
  exit 1
fi

TREED_ROOT="${PI_HOME}/treed"
TREED_MAINSHELLOS_DIR="${TREED_ROOT}/treed-mainshellOS"

THEME_DIR="/usr/share/plymouth/themes/treed"
# Determine the path to cmdline.txt once. Use /boot/firmware on newer Pis or fallback to /boot.
CMDLINE_FILE="/boot/firmware/cmdline.txt"
[ -f "$CMDLINE_FILE" ] || CMDLINE_FILE="/boot/cmdline.txt"
MOONRAKER_URL="http://127.0.0.1:7125"

PRINTER_DATA_DIR="${PI_HOME}/printer_data"
KLIPPER_CONFIG_DIR="${PRINTER_DATA_DIR}/config"
THEME_CONFIG_DIR="${KLIPPER_CONFIG_DIR}/.theme"

export DEBIAN_FRONTEND=noninteractive

FAST="${TREED_FAST:-0}"
STATE_DIR="${TREED_ROOT}/state"
THEME_HASH_FILE="${STATE_DIR}/plymouth_theme.sha"

sudo install -d -m 755 "${STATE_DIR}"
sudo chown -R "$PI_USER":"$(id -gn "$PI_USER")" "${STATE_DIR}" || true

# Install only missing packages. Uses --no-install-recommends for speed.
ensure_packages() {
  local missing=()
  for p in "$@"; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
  done
  if [ ${#missing[@]} -gt 0 ]; then
    sudo apt-get update
    sudo apt-get -y install --no-install-recommends "${missing[@]}"
  fi
}

# Compute a hash of the plymouth theme files in the repository.
theme_hash_repo() {
  find "$REPO_DIR/loader/plymouth/treed" -type f -print0 2>/dev/null \
    | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}'
}

if [ -L "${KLIPPER_CONFIG_DIR}" ]; then
  sudo rm -f "${KLIPPER_CONFIG_DIR}"
fi
sudo install -d -m 755 "${KLIPPER_CONFIG_DIR}"


# Fix: If cloned to staging or elsewhere, copy to standard location and re-exec
if [ "$REPO_DIR" != "${TREED_MAINSHELLOS_DIR}" ]; then
  sudo mkdir -p "${TREED_MAINSHELLOS_DIR}"
  sudo rsync -a --delete "$REPO_DIR/" "${TREED_MAINSHELLOS_DIR}/" || true
  sudo chown -R "$PI_USER":"$(id -gn "$PI_USER")" "${TREED_MAINSHELLOS_DIR}" || true
  cd "${TREED_MAINSHELLOS_DIR}/loader"
  exec ./loader.sh
fi

ensure_packages plymouth plymouth-themes rsync curl

if [ -d "$REPO_DIR/loader/plymouth/treed" ]; then
  sudo install -d -m 755 "$THEME_DIR"

  CUR_HASH="$(theme_hash_repo)"
  PREV_HASH="$(cat "$THEME_HASH_FILE" 2>/dev/null || true)"
  NEED_PLY=0

  [ "$CUR_HASH" != "$PREV_HASH" ] && NEED_PLY=1
  command -v plymouth-set-default-theme >/dev/null 2>&1 || NEED_PLY=1
  [ -e /usr/share/plymouth/themes/default.plymouth ] || NEED_PLY=1
  [ "$(plymouth-set-default-theme 2>/dev/null || true)" = "treed" ] || NEED_PLY=1

  if [ "$NEED_PLY" -eq 1 ]; then
    sudo rsync -a --delete "$REPO_DIR/loader/plymouth/treed/" "$THEME_DIR/"
    sudo chown root:root "$THEME_DIR"/* || true
    sudo chmod 644 "$THEME_DIR"/* || true

    sudo plymouth-set-default-theme treed || true
    [ -e /usr/share/plymouth/themes/default.plymouth ] || sudo ln -sf "${THEME_DIR}/treed.plymouth" /usr/share/plymouth/themes/default.plymouth
    sudo plymouth-set-default-theme -R treed || true

    echo "$CUR_HASH" | sudo tee "$THEME_HASH_FILE" >/dev/null
  fi
fi

# Доп. гарантия: даже если NEED_PLY=0, но вдруг ссылка исчезла — создадим.
[ -e /usr/share/plymouth/themes/default.plymouth ] || sudo ln -sf "${THEME_DIR}/treed.plymouth" /usr/share/plymouth/themes/default.plymouth


if command -v raspi-config >/dev/null 2>&1; then
  sudo raspi-config nonint do_boot_splash 0 || true
fi

if [ -f "$CMDLINE_FILE" ]; then
  # Ensure both serial and tty1 consoles are present and do not remove tty1. If absent, append them.
  grep -q 'console=serial0,115200' "$CMDLINE_FILE" || sudo sed -i '1 s/$/ console=serial0,115200/' "$CMDLINE_FILE"
  grep -q 'console=tty1' "$CMDLINE_FILE" || sudo sed -i '1 s/$/ console=tty1/' "$CMDLINE_FILE"
  # Append other boot parameters if missing: disable screen blanking, enable quiet splash, ignore serial consoles for Plymouth, and hide the blinking cursor.
  grep -q 'consoleblank=0' "$CMDLINE_FILE" || sudo sed -i '1 s/$/ consoleblank=0/' "$CMDLINE_FILE"
  grep -q ' quiet' "$CMDLINE_FILE" || sudo sed -i '1 s/$/ quiet/' "$CMDLINE_FILE"
  grep -q ' splash' "$CMDLINE_FILE" || sudo sed -i '1 s/$/ splash/' "$CMDLINE_FILE"
  grep -q 'plymouth.ignore-serial-consoles' "$CMDLINE_FILE" || sudo sed -i '1 s/$/ plymouth.ignore-serial-consoles/' "$CMDLINE_FILE"
  grep -q 'vt.global_cursor_default=0' "$CMDLINE_FILE" || sudo sed -i '1 s/$/ vt.global_cursor_default=0/' "$CMDLINE_FILE"
fi

sudo systemctl disable --now getty@tty1.service || true

if [ -f "$REPO_DIR/loader/systemd/KlipperScreen.service.d/override.conf" ]; then
  sudo install -d -m 755 /etc/systemd/system/KlipperScreen.service.d
  sudo cp -a "$REPO_DIR/loader/systemd/KlipperScreen.service.d/override.conf" /etc/systemd/system/KlipperScreen.service.d/override.conf
  sudo systemctl daemon-reload
fi

sudo install -d -m 755 "${THEME_CONFIG_DIR}"
if [ -d "$REPO_DIR/mainsail/.theme" ]; then
  sudo rsync -a --delete "$REPO_DIR/mainsail/.theme/" "${THEME_CONFIG_DIR}/" || true
fi
sudo chown -R "$PI_USER":"$(id -gn "$PI_USER")" "${THEME_CONFIG_DIR}" || true

export REPO_DIR TREED_ROOT PI_USER PI_HOME PRINTER_DATA_DIR KLIPPER_CONFIG_DIR

if [ -d "$REPO_DIR/loader/run.d" ]; then
  find "$REPO_DIR/loader/run.d" -type f -name '*.sh' -exec chmod +x {} +
  for s in "$REPO_DIR"/loader/run.d/*.sh; do
    [ -e "$s" ] || continue
    bash "$s"
  done
fi

if [ -d "$REPO_DIR/scripts" ]; then
  find "$REPO_DIR/scripts" -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} +
fi


# Moonraker conf: backup, prefer repo, fallback if none
MOONRAKER_CONF_SOURCE="${REPO_DIR}/moonraker/moonraker.conf"
MOONRAKER_CONF_TARGET="${KLIPPER_CONFIG_DIR}/moonraker.conf"

if [ -f "${MOONRAKER_CONF_TARGET}" ]; then
  cp "${MOONRAKER_CONF_TARGET}" "${MOONRAKER_CONF_TARGET}.bak.$(date +%Y%m%d%H%M%S)" || true
fi

if [ -f "${MOONRAKER_CONF_SOURCE}" ]; then
  echo "[loader] Copying moonraker.conf from repo"
  cp -f "${MOONRAKER_CONF_SOURCE}" "${MOONRAKER_CONF_TARGET}"
else
  echo "[loader] Creating fallback moonraker.conf"
  cat > "${MOONRAKER_CONF_TARGET}" <<'EOF'
[server]
host: 0.0.0.0
port: 7125
klippy_uds_address: /home/pi/printer_data/comms/klippy.sock

[authorization]
cors_domains: *.local *.lan
force_logins: false
trusted_clients: 192.168.0.0/16 10.0.0.0/8 127.0.0.0/8

[update_manager]
enable_auto_refresh: True
EOF
fi

chown "${PI_USER}":"$(id -gn "${PI_USER}")" "${MOONRAKER_CONF_TARGET}" || true

sudo systemctl restart moonraker.service || true

if command -v curl >/dev/null 2>&1; then
  # Wait for Moonraker to come up. Use fewer attempts in fast mode.
  tries=30
  [ "$FAST" = "1" ] && tries=10
  for i in $(seq 1 $tries); do
    if curl -fsS --connect-timeout 3 --max-time 5 "${MOONRAKER_URL}/server/info" >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done

  # Always refresh update information.
  curl -sS --connect-timeout 3 --max-time 5 -H "Content-Type: application/json" \
       -d '{"jsonrpc":"2.0","method":"machine.update.refresh","params":{},"id":1}' \
       "${MOONRAKER_URL}/jsonrpc" || true

  # Perform upgrade only in non-fast mode.
  if [ "$FAST" != "1" ]; then
    curl -sS --connect-timeout 5 --max-time 15 -H "Content-Type: application/json" \
         -d '{"jsonrpc":"2.0","method":"machine.update.upgrade","params":{},"id":2}' \
         "${MOONRAKER_URL}/jsonrpc" || true
  fi
fi

TREED_KLIPPER_SOURCE="${TREED_MAINSHELLOS_DIR}/klipper"
TREED_KLIPPER_TARGET="${TREED_ROOT}/klipper"
TREED_KLIPPER_SWITCH="${TREED_KLIPPER_TARGET}/switch_profile.sh"

if [ -d "${TREED_KLIPPER_SOURCE}" ]; then
  mkdir -p "${TREED_KLIPPER_TARGET}"
  rsync -a "${TREED_KLIPPER_SOURCE}/" "${TREED_KLIPPER_TARGET}/"
fi

PRINTER_CFG="${KLIPPER_CONFIG_DIR}/printer.cfg"
TREED_KLIPPER_ENTRY="${TREED_KLIPPER_TARGET}/printer_root.cfg"

if [ -f "${TREED_KLIPPER_ENTRY}" ]; then
  if [ -f "${PRINTER_CFG}" ] && [ ! -L "${PRINTER_CFG}" ]; then
    cp "${PRINTER_CFG}" "${PRINTER_CFG}.bak.$(date +%Y%m%d%H%M%S)"
  fi

  cat > "${PRINTER_CFG}" <<EOF
[include ${TREED_KLIPPER_ENTRY}]
EOF
fi

if [ -x "${TREED_KLIPPER_SWITCH}" ]; then
  "${TREED_KLIPPER_SWITCH}" rn12_hbot_v1 || true
fi

"${REPO_DIR}/loader/klipper-config.sh" || true
sudo systemctl restart klipper.service || true

# Reload systemd to pick up any new or changed service units.
sudo systemctl daemon-reload

# Flush filesystem buffers to disk once. Multiple syncs are redundant.
sync

echo "[loader] Installation complete. Rebooting in 5 seconds..."
sleep 5
sudo reboot
