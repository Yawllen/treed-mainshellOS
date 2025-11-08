#!/bin/bash
set -e
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
sudo install -d -m 755 /usr/share/plymouth/themes/treed
sudo cp -a "$REPO_DIR/loader/plymouth/treed/treed.plymouth" /usr/share/plymouth/themes/treed/
sudo cp -a "$REPO_DIR/loader/plymouth/treed/treed.script" /usr/share/plymouth/themes/treed/
sudo cp -a "$REPO_DIR/loader/plymouth/treed/watermark.png" /usr/share/plymouth/themes/treed/ 2>/dev/null || true
sudo chown root:root /usr/share/plymouth/themes/treed/*
sudo chmod 0644 /usr/share/plymouth/themes/treed/*
sudo plymouth-set-default-theme -R treed
sudo install -d -m 755 /etc/systemd/system/KlipperScreen.service.d
sudo cp -a "$REPO_DIR/loader/systemd/KlipperScreen.service.d/override.conf" /etc/systemd/system/KlipperScreen.service.d/override.conf
sudo systemctl daemon-reload
sudo install -d -m 755 /home/pi/printer_data/config/.theme
sudo rsync -a --delete "$REPO_DIR/mainsail/.theme/" /home/pi/printer_data/config/.theme/
sudo chown -R pi:$(id -gn pi) /home/pi/printer_data/config/.theme
