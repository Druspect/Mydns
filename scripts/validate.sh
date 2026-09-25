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

pass=0
fail=0

check() {
  local name="$1"
  shift
  printf '%-46s' "$name"
  if "$@" >/dev/null 2>&1; then
    echo "PASS"
    pass=$((pass + 1))
  else
    echo "FAIL"
    fail=$((fail + 1))
  fi
}

echo "=== mydns validation ==="
echo "Device: $DEVICE"
echo

check "ADB shell reachable" "${ADB[@]}" shell true
check "Raw IPv4 connectivity to 1.1.1.1" "${ADB[@]}" shell ping -c 1 -W 3 1.1.1.1
check "DNS resolution for example.com" "${ADB[@]}" shell ping -c 1 -W 5 example.com
check "DNS resolution for nextdns.io" "${ADB[@]}" shell ping -c 1 -W 5 nextdns.io

MODE="$("${ADB[@]}" shell settings get global private_dns_mode 2>/dev/null | tr -d '\r')"
SPEC="$("${ADB[@]}" shell settings get global private_dns_specifier 2>/dev/null | tr -d '\r')"

printf '%-46s' "Private DNS mode is hostname"
if [[ "$MODE" == "hostname" ]]; then
  echo "PASS"
  pass=$((pass + 1))
else
  echo "FAIL ($MODE)"
  fail=$((fail + 1))
fi

printf '%-46s' "Private DNS hostname is NextDNS"
if [[ "$SPEC" == *.dns.nextdns.io ]]; then
  echo "PASS ($SPEC)"
  pass=$((pass + 1))
else
  echo "FAIL ($SPEC)"
  fail=$((fail + 1))
fi

echo
echo "Opening NextDNS test page on the handset..."
"${ADB[@]}" shell am start -a android.intent.action.VIEW -d "https://test.nextdns.io/" >/dev/null 2>&1 || true

echo
echo "Manual checks:"
echo "  1. Proton VPN still shows Connected."
echo "  2. https://test.nextdns.io reports the intended profile."
echo "  3. Browser pages load normally."
echo "  4. Test Pinterest, Facebook/Instagram, X, messaging, banking, and work apps."
echo
echo "Automated checks: $pass passed, $fail failed."

if [[ "$fail" -gt 0 ]]; then
  echo "Validation failed. Consider rollback:"
  echo "  ./scripts/mydns.sh --rollback"
  exit 1
fi
