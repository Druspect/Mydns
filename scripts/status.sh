#!/usr/bin/env bash
set -Eeuo pipefail

command -v adb >/dev/null 2>&1 || {
  echo "ERROR: adb is required." >&2
  exit 1
}

devices="$(adb devices | awk 'NR>1 && $2=="device" {print $1}')"
count="$(printf '%s\n' "$devices" | sed '/^$/d' | wc -l | tr -d ' ')"

[[ "$count" -eq 1 ]] || {
  echo "ERROR: Expected exactly one authorized ADB device; found $count." >&2
  exit 1
}

DEVICE="$devices"
ADB=(adb -s "$DEVICE")

prop() {
  "${ADB[@]}" shell getprop "$1" 2>/dev/null | tr -d '\r'
}

setting() {
  "${ADB[@]}" shell settings get global "$1" 2>/dev/null | tr -d '\r'
}

echo "=== mydns device status ==="
echo "ADB serial:              $DEVICE"
echo "Manufacturer:            $(prop ro.product.manufacturer)"
echo "Model:                   $(prop ro.product.model)"
echo "Android version:         $(prop ro.build.version.release)"
echo "SDK level:               $(prop ro.build.version.sdk)"
echo "Build fingerprint:       $(prop ro.build.fingerprint)"
echo
echo "Private DNS mode:        $(setting private_dns_mode)"
echo "Private DNS specifier:   $(setting private_dns_specifier)"
echo
echo "Proton VPN package check:"

found=0
for pkg in ch.protonvpn.android com.protonvpn.android; do
  if "${ADB[@]}" shell pm list packages 2>/dev/null | grep -q "package:$pkg"; then
    echo "  FOUND: $pkg"
    found=1
  fi
done

if [[ "$found" -eq 0 ]]; then
  echo "  Proton VPN package not detected under expected package names."
fi
