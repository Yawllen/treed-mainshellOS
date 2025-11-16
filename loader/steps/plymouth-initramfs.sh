#!/bin/bash
set -euo pipefail

theme_name="treed"
def="/usr/share/plymouth/themes/default.plymouth"

sudo plymouth-set-default-theme "${theme_name}"
sudo plymouth-set-default-theme --rebuild-initrd "${theme_name}"

kernel="$(uname -r)"
img="/boot/initrd.img-${kernel}"

sudo update-initramfs -u -k "${kernel}"

sudo lsinitramfs "$img" | grep -q '^usr/share/plymouth/themes/treed/treed.plymouth$'
sudo lsinitramfs "$img" | grep -q '^usr/share/plymouth/themes/treed/treed.script$'

readlink -f "$def" | grep -q '/usr/share/plymouth/themes/treed/treed.plymouth'
