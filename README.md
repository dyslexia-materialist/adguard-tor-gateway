# AGGuard — Self-hosted Home Network Gateway

A single-VPS home network gateway combining:

- **Network-wide ad blocking** — every device, zero client config (AdGuard Home over a WireGuard tunnel)
- **Selective routing** — blocked domains exit through Tor; everything else stays on your home ISP
- **Self-learning blocklist** — auto-detects DNS-poisoned and SNI/TLS-reset blocking
- **One-command restore** — `restore.sh` re-syncs everything after any outage

## Setup

See `config/gateway.env.example` for all variables and `docs/troubleshooting.md`
for the hard-won gotchas (cryptokey routing, key regeneration, MTU/MSS, DoH bypass).

## Disclaimer

Personal-use project. You are responsible for complying with the laws of your
jurisdiction. No warranty.
