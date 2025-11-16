#!/bin/bash
set -euo pipefail

src_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../plymouth/theme/treed" && pwd)"
dst_dir="/usr/share/plymouth/themes/treed"

sudo rsync -a --delete "${src_dir}/" "${dst_dir}/"
test -f "${dst_dir}/treed.plymouth"
test -f "${dst_dir}/treed.script"
