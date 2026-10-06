#!/usr/bin/env bash
set -u
source "$(dirname "$0")/../config/gateway.env"
DOMAIN=$(echo "${1:-}" | tr 'A-Z' 'a-z' | sed 's/^www\.//')
[ -z "$DOMAIN" ] && { echo "Kullanım: $0 <domain>"; exit 1; }
SSHCMD="sshpass -f $KEEN_PASSFILE ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 admin@$KEEN_HOST"

G_IP=$(dig +short @$CLEAN_DNS "$DOMAIN" 2>/dev/null | tail -n1)
TR_IP=$(dig +short @$TT_RESOLVER "$DOMAIN" 2>/dev/null | tail -n1)
echo "Clean: ${G_IP:-YOK} | ISP: ${TR_IP:-YOK}"
poison=0
for p in $POISON_IPS; do [ "$TR_IP" = "$p" ] && poison=1; done
[ -z "$TR_IP" ] && poison=1

if [ "$poison" = 0 ]; then
    echo "TEMİZ — listeye eklenmedi"; exit 0
fi
echo "ENGELLİ — push ediliyor..."
$SSHCMD "object-group fqdn domain-list0 include ${DOMAIN}" >/dev/null 2>&1
for host in "$DOMAIN" "www.$DOMAIN"; do
  for ip in $(dig +short @$AGH_DNS "$host" 2>/dev/null | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/'); do
    [ "$ip" = "$AGH_DNS" ] || [ "$ip" = "0.0.0.0" ] || continue
    $SSHCMD "ip route ${ip} $KEEN_IFACE" >/dev/null 2>&1 && echo "✓ rota: ${ip} (${host})"
  done
done
$SSHCMD "system configuration save" >/dev/null 2>&1
echo "$(date '+%F %T') ${DOMAIN} [check-and-ban]" >> "$ADDED_LOG"
