# mydns

ADB-based Android DNS deployment toolkit for using **NextDNS with Proton VPN already installed**.

The goal is simple:

1. Configure Android Private DNS to a NextDNS profile.
2. Keep Proton VPN as the device VPN.
3. Validate that normal internet access, DNS resolution, and Proton VPN still work.
4. Roll back immediately if the test device loses connectivity.
5. Only then deploy the same configuration to additional Android devices.

## Supported Android devices

Designed for Android 9+ devices that expose standard Android Private DNS settings, including:

- OnePlus / OxygenOS
- Samsung Galaxy / One UI
- Motorola / My UX
- Google Pixel / stock Android
- Most other Android 9+ devices

OEM behavior can vary. Always run the validation step on each device class before wider deployment.

## Requirements

Host computer:

- `adb`
- Bash
- USB debugging enabled on the Android test device

Android device:

- Android 9+
- Proton VPN already installed and configured
- An active NextDNS configuration ID

## Quick start

Connect exactly one test phone over ADB:

```bash
adb devices
```

Copy the example config:

```bash
cp config/example.env config/local.env
```

Edit `config/local.env`:

```bash
NEXTDNS_CONFIG_ID="abcdef"
```

Do **not** commit `config/local.env`.

Deploy:

```bash
chmod +x scripts/*.sh
./scripts/mydns.sh --config config/local.env
```

Validate:

```bash
./scripts/validate.sh
```

Inspect current DNS state:

```bash
./scripts/status.sh
```

Rollback:

```bash
./scripts/mydns.sh --rollback
```

## Architecture

```text
Android device
    |
    +-- Proton VPN app
    |      |
    |      +-- encrypted VPN tunnel
    |
    +-- Android Private DNS
           |
           +-- <config-id>.dns.nextdns.io
                   |
                   +-- NextDNS filtering policy
```

This project deliberately avoids installing a second local-VPN ad blocker. Android normally permits only one active VPN service, so the design keeps Proton VPN in that slot and uses Android Private DNS for filtering.

## Filter policy

The recommended policy is intentionally staged.

Baseline:

- NextDNS threat-intelligence/security features
- Ads and tracker blocking
- HaGeZi Multi PRO or equivalent balanced list
- Threat intelligence feeds
- Native tracking protection where appropriate
- Custom denylist entries for known nuisance/scam domains

Avoid starting with the most aggressive social-media blocklists. Meta, X, Pinterest, Messenger, Instagram, and related services share infrastructure with legitimate app functions, and overly broad lists can break login, media, messaging, or push notifications.

See [docs/filter-policy.md](docs/filter-policy.md).

## Security model

This repository does **not** store:

- NextDNS account credentials
- Proton credentials
- VPN credentials
- device serials
- private API keys

A NextDNS configuration ID should be kept in an ignored local config file.

## Test-first rollout

Recommended sequence:

1. One disposable/test Android phone.
2. Confirm Proton VPN connects.
3. Confirm `test.nextdns.io` reports the intended profile.
4. Confirm browser access.
5. Confirm DNS resolution.
6. Test Pinterest, Facebook, Instagram, X, messaging, banking, and any required work apps.
7. Leave the device in normal use for a while.
8. Repeat on one phone from each OEM family.
9. Deploy to primary devices only after validation.

## Important limitation

DNS filtering blocks **domains/hostnames**, not arbitrary page paths.

It can block:

```text
ads.example.com
tracker.example.net
```

It cannot distinguish:

```text
example.com/allowed
example.com/blocked
```

when both use the same hostname.

## Repository layout

```text
mydns/
├── README.md
├── LICENSE
├── .gitignore
├── config/
│   └── example.env
├── docs/
│   ├── device-support.md
│   └── filter-policy.md
└── scripts/
    ├── mydns.sh
    ├── status.sh
    └── validate.sh
```

## Safety

Always keep rollback available before changing DNS settings on a primary phone. A malformed Private DNS hostname or a provider outage can make DNS-based internet access appear completely broken even when the underlying network connection is still active.
