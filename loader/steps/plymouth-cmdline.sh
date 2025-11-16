#!/bin/bash
set -euo pipefail

cmd="/boot/firmware/cmdline.txt"

current="$(cat "$cmd")"
wanted="quiet splash plymouth.ignore-serial-consoles vt.global_cursor_default=0 logo.nologo loglevel=3 systemd.show_status=false rd.systemd.show_status=false"
for k in $wanted; do
  echo "$current" | grep -qw "$k" || current="$current $k"
done
echo "$current" | sed 's/  \+/ /g;s/ *$//' | sudo tee "$cmd" >/dev/null
