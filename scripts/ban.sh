#!/usr/bin/env bash
set -u
source "$(dirname "$0")/../config/gateway.env"
DOMAIN=$(echo "${1:-}" | tr 'A-Z' 'a-z' | sed 's/^www\.//')
[ -z "$DOMAIN" ] && { echo "Kullanım: $0 <domain>"; exit 1; }
SSHCMD="sshpass -f $KEEN_PASSFILE ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 admin@$KEEN_HOST"

grep -qx "$DOMAIN" "$BANNED_LIST" || echo "$DOMAIN" >> "$BANNED_LIST"
$SSHCMD "object-group fqdn domain-list0 include ${DOMAIN}" >/dev/null 2>&1
for host in "$DOMAIN" "www.$DOMAIN"; do
  for ip in $(dig +short @$AGH_DNS "$host" 2>/dev/null | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/'); do
    [ "$ip" = "$AGH_DNS" ] || [ "$ip" = "0.0.0.0" ] || continue
    $SSHCMD "ip route ${ip} $KEEN_IFACE" >/dev/null 2>&1 && echo "✓ rota: ${ip} (${host})"
  done
done
$SSHCMD "system configuration save" >/dev/null 2>&1
echo "$(date '+%F %T') ${DOMAIN} [ban.sh]" >> "$ADDED_LOG"
