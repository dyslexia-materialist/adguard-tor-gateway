[English](README.md) | [Türkçe](README.tr.md)

# AGGuard — Self-hosted Home Network Gateway

A single-VPS home network gateway combining:

- **Network-wide ad blocking** — every device, zero client config (AdGuard Home over a WireGuard tunnel)
- **Selective routing** — blocked domains exit through Tor; everything else stays on your home ISP
- **Self-learning blocklist** — auto-detects DNS-poisoned and SNI/TLS-reset blocking
- **One-command restore** — `restore.sh` re-syncs everything after any outage

## Architecture

    Client devices
          |
          v
    Home router (WireGuard client)
          |  routes: blocked IPs -> tunnel
          v
    VPS gateway (single server)
          |- AdGuard Home --> DNS answers (ads = 0.0.0.0)
          |- redsocks --> Tor (SOCKS5) --> blocked-site traffic exits here
          +- policy routing --> normal traffic exits via home ISP

## How detection works

| Block type | Detector | Where |
|---|---|---|
| DNS poisoning | Server watcher: clean resolver vs ISP resolver per new domain | VPS (AdGuard query log) |
| SNI / TLS-reset | Windows client helper: TCP connect OK + TLS handshake reset = blocked | PC (DNS cache watcher) |

Both detectors push the domain to the gateway, which adds it to the router's
route table and (optionally) a DNS allowlist bypass.

## Setup

1. **VPS**: WireGuard, AdGuard Home (host network), Tor + redsocks
2. **Router**: WireGuard tunnels to the VPS — one public (traffic), one private (management)
3. **Router DNS**: point the router's resolver at AdGuard Home (tunnel IP)
4. **Static routes**: route blocked-domain IPs through the tunnel
5. **Client helper (optional, Windows)**: DNS-cache watcher for SNI-block auto-detection

See `config/gateway.env.example` for all variables and `docs/troubleshooting.md`
for the gotchas.

## Scripts

| Script | Purpose |
|---|---|
| scripts/watch.sh | AdGuard query-log watcher: poison test per new domain, auto-route |
| scripts/ban.sh | Manual ban: route a domain through the tunnel |
| scripts/restore.sh | Re-push all routes + domain list after any outage |
| scripts/cleanup-routes.sh | Remove wrongly-added routes (keep-list based) |
| client/ban-helper.ps1 | Windows DNS-cache watcher: poison + SNI-reset detection |

## Disclaimer

Personal-use project. You are responsible for complying with the laws of your
jurisdiction. No warranty.
