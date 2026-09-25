# Device support

## Baseline requirement

`mydns` relies on Android Private DNS, introduced in Android 9.

The ADB settings used are:

```text
private_dns_mode
private_dns_specifier
```

The expected configured values are:

```text
private_dns_mode=hostname
private_dns_specifier=<config-id>.dns.nextdns.io
```

## OEM families

### OnePlus / OxygenOS

Expected to use standard Android Private DNS behavior.

Validate:

- Proton VPN remains connected.
- DNS resolves while Proton is active.
- Reboot the handset and confirm settings persist.
- Test switching between Wi-Fi and cellular.

### Samsung / One UI

Expected to use standard Android Private DNS behavior.

Validate:

- Secure Wi-Fi or other Samsung network-security features are not competing with the intended configuration.
- Private DNS persists after reboot.
- Proton VPN auto-connect/always-on behavior remains intact.

### Motorola / My UX

Generally close to stock Android networking.

Validate:

- Wi-Fi to cellular transitions.
- Proton VPN reconnect behavior.
- DNS state after reboot.

### Google Pixel / stock Android

This is the closest reference behavior for Android Private DNS.

Validate:

- Always-on VPN behavior if enabled.
- Private DNS state after reboot.
- Captive portal behavior on public Wi-Fi.

## Captive portals

Public Wi-Fi sign-in portals can behave badly when Private DNS is forced to a hostname before the network grants full internet access.

If a captive portal will not load:

1. Disconnect Proton VPN temporarily if required by that network.
2. Temporarily set Private DNS to Automatic.
3. Complete the captive-portal sign-in.
4. Restore the NextDNS configuration.
5. Reconnect Proton VPN.
6. Re-run validation.

Do not normalize this workaround into permanent behavior. It should only be used when a specific captive portal requires it.

## Unsupported/untested

- Android 8 and earlier
- heavily modified vendor ROMs that do not honor standard Private DNS settings
- devices managed by an MDM that locks network settings
- configurations using another app that occupies Android's VPN slot
