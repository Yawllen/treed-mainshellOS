#!/bin/bash
set -euo pipefail

kernel="$(uname -r)"
img_name="initrd.img-${kernel}"
src="/boot/${img_name}"
dst="/boot/firmware/${img_name}"
cfg="/boot/firmware/config.txt"

export DEBIAN_FRONTEND=noninteractive
sudo apt-get update
sudo apt-get -y install initramfs-tools

if [ ! -f "$src" ]; then
  sudo update-initramfs -c -k "${kernel}"
fi

if [ ! -f "$dst" ]; then
  sudo install -m644 "$src" "$dst"
fi

sudo sed -i '/^initramfs /d' "$cfg"
echo "initramfs ${img_name} followkernel" | sudo tee -a "$cfg" >/dev/null

test -f "$dst"
grep -q "^initramfs ${img_name}" "$cfg"
