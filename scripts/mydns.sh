#!/usr/bin/env bash
set -Eeuo pipefail

BACKUP_DIR="${HOME}/.mydns"
BACKUP_FILE="${BACKUP_DIR}/android_private_dns_backup.env"

die() {
  echo "ERROR: $*" >&2
  exit 1
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "'$1' is required but was not found."
}

need_cmd adb

CONFIG_FILE=""
CONFIG_ID=""
ROLLBACK=0

usage() {
  cat <<'EOF'
Usage:
  ./scripts/mydns.sh --config config/local.env
  ./scripts/mydns.sh --id NEXTDNS_CONFIG_ID
  ./scripts/mydns.sh --rollback

Options:
  --config FILE   Read NEXTDNS_CONFIG_ID from FILE
  --id ID         Supply the NextDNS config ID directly
  --rollback      Restore the previous Android Private DNS settings
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --config)
      [[ $# -ge 2 ]] || die "--config requires a file path"
      CONFIG_FILE="$2"
      shift 2
      ;;
    --id)
      [[ $# -ge 2 ]] || die "--id requires a value"
      CONFIG_ID="$2"
      shift 2
      ;;
    --rollback)
      ROLLBACK=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

get_device() {
  local devices count
  devices="$(adb devices | awk 'NR>1 && $2=="device" {print $1}')"
  count="$(printf '%s\n' "$devices" | sed '/^$/d' | wc -l | tr -d ' ')"
  [[ "$count" -eq 1 ]] || die "Expected exactly one authorized ADB device; found $count."
  printf '%s\n' "$devices"
}

DEVICE="$(get_device)"
ADB=(adb -s "$DEVICE")

get_setting() {
  "${ADB[@]}" shell settings get global "$1" 2>/dev/null | tr -d '\r'
}

set_setting() {
  "${ADB[@]}" shell settings put global "$1" "$2"
}

delete_setting() {
  "${ADB[@]}" shell settings delete global "$1" >/dev/null 2>&1 || true
}

show_status() {
  echo "Device:                 $DEVICE"
  echo "Private DNS mode:       $(get_setting private_dns_mode)"
  echo "Private DNS specifier:  $(get_setting private_dns_specifier)"
}

rollback() {
  if [[ ! -f "$BACKUP_FILE" ]]; then
    echo "No backup exists. Restoring Android Private DNS to Automatic."
    set_setting private_dns_mode opportunistic
    delete_setting private_dns_specifier
    show_status
    return
  fi

  # shellcheck disable=SC1090
  source "$BACKUP_FILE"

  if [[ -n "${OLD_MODE:-}" && "${OLD_MODE:-}" != "null" ]]; then
    set_setting private_dns_mode "$OLD_MODE"
  else
    set_setting private_dns_mode opportunistic
  fi

  if [[ -n "${OLD_SPECIFIER:-}" && "${OLD_SPECIFIER:-}" != "null" ]]; then
    set_setting private_dns_specifier "$OLD_SPECIFIER"
  else
    delete_setting private_dns_specifier
  fi

  echo "Rollback complete."
  show_status
}

if [[ "$ROLLBACK" -eq 1 ]]; then
  rollback
  exit 0
fi

if [[ -n "$CONFIG_FILE" ]]; then
  [[ -f "$CONFIG_FILE" ]] || die "Config file not found: $CONFIG_FILE"
  # shellcheck disable=SC1090
  source "$CONFIG_FILE"
  CONFIG_ID="${NEXTDNS_CONFIG_ID:-}"
fi

[[ -n "$CONFIG_ID" ]] || die "No NextDNS configuration ID supplied."
[[ "$CONFIG_ID" =~ ^[A-Za-z0-9_-]+$ ]] || die "Unexpected characters in NextDNS configuration ID."

NEXTDNS_HOST="${CONFIG_ID}.dns.nextdns.io"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

OLD_MODE="$(get_setting private_dns_mode)"
OLD_SPECIFIER="$(get_setting private_dns_specifier)"

cat > "$BACKUP_FILE" <<EOF
OLD_MODE=$(printf '%q' "$OLD_MODE")
OLD_SPECIFIER=$(printf '%q' "$OLD_SPECIFIER")
EOF
chmod 600 "$BACKUP_FILE"

echo "Applying NextDNS Private DNS to $DEVICE"
echo "Hostname: $NEXTDNS_HOST"

set_setting private_dns_mode hostname
set_setting private_dns_specifier "$NEXTDNS_HOST"

sleep 2
show_status

echo
echo "Run ./scripts/validate.sh next."
echo "Rollback at any time with: ./scripts/mydns.sh --rollback"
