#!/usr/bin/env bash
set -u
source "$(dirname "$0")/../config/gateway.env"
SSHCMD="sshpass -f $KEEN_PASSFILE ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 admin@$KEEN_HOST"

KEEP_IPS="$AGH_DNS"
for d in $(grep -vE '^\s*(#|$)' "$BANNED_LIST"); do
    for ip in $(dig +short @$AGH_DNS "$d" 2>/dev/null | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/'); do
        KEEP_IPS="$KEEP_IPS $ip"
    done
done

grep -oE 'ip:[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' "$ADDED_LOG" | cut -d: -f2 | sort -u | while read -r ip; do
    keep=0
    for k in $KEEP_IPS; do [ "$ip" = "$k" ] && keep=1; done
    [ "$keep" = 0 ] && $SSHCMD "no ip route ${ip} $KEEN_IFACE" >/dev/null 2>&1 && echo "✓ silindi: $ip"
done
$SSHCMD "system configuration save" >/dev/null 2>&1
