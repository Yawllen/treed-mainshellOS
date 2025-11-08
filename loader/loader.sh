#!/bin/bash
set -e
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sudo apt-get update
sudo apt-get -y install plymouth plymouth-themes rsync
sudo install -d -m 755 /usr/share/plymouth/themes/treed
sudo cp -a "$REPO_DIR/loader/plymouth/treed/"* /usr/share/plymouth/themes/treed/
sudo chown root:root /usr/share/plymouth/themes/treed/*
sudo chmod 0644 /usr/share/plymouth/themes/treed/*
if command -v plymouth-set-default-theme >/dev/null 2>&1; then
sudo plymouth-set-default-theme -R treed || sudo plymouth-set-default-theme treed
fi
if [ -f "$REPO_DIR/loader/systemd/KlipperScreen.service.d/override.conf" ]; then
sudo install -d -m 755 /etc/systemd/system/KlipperScreen.service.d
sudo cp -a "$REPO_DIR/loader/systemd/KlipperScreen.service.d/override.conf" /etc/systemd/system/KlipperScreen.service.d/override.conf
sudo systemctl daemon-reload
fi
sudo install -d -m 755 /home/pi/printer_data/config/.theme
sudo rsync -a --delete "$REPO_DIR/mainsail/.theme/" /home/pi/printer_data/config/.theme/
sudo chown -R pi:$(id -gn pi) /home/pi/printer_data/config/.theme
