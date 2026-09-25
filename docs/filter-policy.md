# NextDNS filter policy

This project separates **device deployment** from **DNS policy**.

ADB configures the Android device. The actual allow/block decisions are configured in the NextDNS web console.

## Objectives

The target policy is:

1. malware and phishing protection
2. scam-domain blocking
3. advertising and tracking reduction
4. social-media advertising/telemetry reduction
5. known malicious infrastructure blocking
6. minimal breakage to normal apps and authentication

The policy should not be based on nationality alone. Blocking entire countries or TLDs is noisy and can create collateral damage. Prefer reputable threat-intelligence feeds containing specific malicious domains and infrastructure indicators.

## Recommended staged policy

### Stage 1: security baseline

Enable the relevant NextDNS security protections available in your profile, such as:

- threat-intelligence feeds
- malicious-domain protection
- phishing protection
- cryptojacking protection
- DNS rebinding protection
- typo-squatting / lookalike-domain protections where appropriate
- newly registered domain protection only if your app compatibility remains acceptable

Then validate the phone.

### Stage 2: balanced ads and trackers

Add a balanced maintained list such as:

- HaGeZi Multi PRO

PRO is preferable for the first rollout because it is aggressive enough to reduce ads and trackers without deliberately maximizing breakage.

Do not start with the most aggressive/Ultimate tier on your primary devices.

### Stage 3: social-media tracking and advertising

Use NextDNS native tracking protections and/or maintained lists that specifically target tracking infrastructure.

Priority services for testing:

- Pinterest
- Facebook
- Instagram
- Messenger
- X
- Reddit
- TikTok
- Snapchat

Be careful with blanket domain blocking. Social platforms frequently serve application content, authentication, telemetry, and advertisements from overlapping infrastructure.

The goal is to block third-party advertising and tracking endpoints while preserving:

- login
- MFA
- posts/feed retrieval
- images/video
- messaging
- push notifications

### Stage 4: custom denylist

Use the NextDNS denylist for exact domains that repeatedly appear in logs and are clearly unwanted.

Good candidates:

- confirmed ad endpoints
- confirmed tracking endpoints
- confirmed scam domains
- known malware/C2 infrastructure
- unwanted telemetry endpoints that do not break required features

Avoid speculative entries.

## Nation-state threat handling

Treat this as a threat-intelligence problem rather than a geopolitical domain-blocking problem.

Recommended approach:

- consume maintained threat-intelligence lists
- block exact malicious FQDNs
- block known phishing and malware infrastructure
- use reputable security feeds with active maintenance
- review false positives
- avoid blanket country-code TLD blocks unless you have a separate operational reason

DNS filtering alone is not sufficient protection against a sophisticated state-backed actor. Pair it with:

- current Android security patches
- Proton VPN on untrusted networks
- strong MFA/passkeys
- browser/app isolation where appropriate
- avoiding sideloaded APKs from untrusted sources
- Play Protect or another trusted mobile security control
- prompt patching of browsers, WebView, and messaging apps

## Rollout sequence

1. Configure the policy.
2. Deploy to one test phone.
3. Run `scripts/validate.sh`.
4. Use the handset normally.
5. Review the NextDNS logs for unexpected blocks.
6. Add allowlist exceptions only when justified.
7. Test one handset from each OEM family.
8. Roll out to primary devices last.

## What DNS cannot block

DNS sees hostnames, not full encrypted HTTPS paths.

It can block:

```text
ads.vendor.example
tracker.vendor.example
```

It cannot selectively block:

```text
social.example/ad
```

while allowing:

```text
social.example/feed
```

if both use the same hostname.

For first-party advertising served from the same hostname as normal content, DNS filtering may not be able to remove the ad without also breaking the application.
