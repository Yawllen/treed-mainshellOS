#!/bin/bash
set -euo pipefail

STATE_DIR="${STATE_DIR:-/home/pi/treed/state/cmdline}"
CMDLINE_FILE="${CMDLINE_FILE:-/boot/firmware/cmdline.txt}"
[ -f "$CMDLINE_FILE" ] || CMDLINE_FILE="/boot/cmdline.txt"
EXPECTED_FILE="${STATE_DIR}/cmdline.expected"

ts() { date +"%Y-%m-%d %H:%M:%S"; }

normalize_line() {
  local line=" $1 "
  line="${line//[$'\n\r']/ }"
  line="$(printf '%s' "$line" | sed -E 's/(^| )nosplash( |$)/ /g')"
  line="$(printf '%s' "$line" | sed -E 's/(^| )plymouth\.enable=0( |$)/ /g')"
  for opt in quiet splash plymouth.ignore-serial-consoles logo.nologo vt.global_cursor_default=0; do
    case " $line " in *" $opt "*) ;; *) line="$line $opt" ;; esac
  done
  line="$(printf '%s' "$line" | tr -s ' ' | sed 's/^ //; s/ $//')"
  printf '%s' "$line"
}

ensure_state() { mkdir -p "$STATE_DIR"; }

build_expected_from_current() {
  local cur; cur="$(tr -d '\n' < "$CMDLINE_FILE")"
  local norm; norm="$(normalize_line "$cur")"
  printf '%s\n' "$norm" > "$EXPECTED_FILE"
  echo "$(ts) [treed-cmdline-guard] built expected from current"
}

init_cmd() {
  ensure_state
  if [ ! -f "$EXPECTED_FILE" ]; then
    build_expected_from_current
  fi
}

enforce_cmd() {
  ensure_state
  [ -f "$EXPECTED_FILE" ] || build_expected_from_current
  local expected current
  expected="$(tr -d '\n' < "$EXPECTED_FILE")"
  current="$(tr -d '\n' < "$CMDLINE_FILE")"
  if [ "$current" != "$expected" ]; then
    printf '%s\n' "$expected" | sudo tee "$CMDLINE_FILE" >/dev/null
    echo "$(ts) [treed-cmdline-guard] restored cmdline.txt"
  else
    echo "$(ts) [treed-cmdline-guard] ok"
  fi
}

status_cmd() {
  ensure_state
  local e h
  if [ -f "$EXPECTED_FILE" ]; then e="$(sha256sum "$EXPECTED_FILE" | awk '{print $1}')"; else e="missing"; fi
  if [ -f "$CMDLINE_FILE" ]; then h="$(sha256sum "$CMDLINE_FILE" | awk '{print $1}')"; else h="missing"; fi
  echo "expected=$e current=$h file=$CMDLINE_FILE expected_file=$EXPECTED_FILE"
  [ "$e" = "$h" ] && exit 0 || exit 3
}

bless_cmd() {
  ensure_state
  build_expected_from_current
  echo "$(ts) [treed-cmdline-guard] blessed new expected"
}

case "${1:-}" in
  init) init_cmd ;;
  enforce|guard) enforce_cmd ;;
  status) status_cmd ;;
  bless) bless_cmd ;;
  *) echo "usage: $0 {init|enforce|guard|status|bless}" ; exit 2 ;;
esac
