#!/bin/bash
set -e
TARGET_DIR="/home/pi/treed"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
mkdir -p "$TARGET_DIR"
rsync -a --delete --exclude '.git' --exclude '.github' --exclude '.staging' --exclude 'loader' --exclude 'moonraker.conf' --exclude 'KlipperScreen.conf' "$REPO_DIR/" "$TARGET_DIR/"
systemctl restart moonraker.service || true
systemctl restart klipper.service || true
systemctl restart KlipperScreen.service || true
