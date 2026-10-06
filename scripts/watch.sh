#!/usr/bin/env bash
set -u
source "$(dirname "$0")/../config/gateway.env"
QLOG="$AGH_QUERYLOG"; LIST="$BANNED_LIST"; STATE="$ADDED_LOG"
SSHCMD="sshpass -f $KEEN_PASSFILE ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 admin@$KEEN_HOST"

tail -Fn0 "$QLOG" 2>/dev/null | while read -r line; do
    d=$(echo "$line" | grep -oE '"domain":"[^"]+"' | head -1 | cut -d'"' -f4)
    [ -z "$d" ] && continue
    base=$(echo "$d" | awk -F. '{print $(NF-1)"."$NF}')
    grep -q " ${base}\$" "$STATE" 2>/dev/null && continue

    inlist=0
    grep -qx "$base" "$LIST" 2>/dev/null && inlist=1

    if [ "$inlist" != 1 ]; then
        G_IP=$(dig +short +time=2 +tries=1 @$CLEAN_DNS "$base" 2>/dev/null | tail -n1)
        [ -z "$G_IP" ] && continue
        TR_IP=$(dig +short +time=2 +tries=1 @$TT_RESOLVER "$base" 2>/dev/null | tail -n1)
        banned=0
        for p in $POISON_IPS; do [ "$TR_IP" = "$p" ] && banned=1; done
        [ -z "$TR_IP" ] && banned=1
        [ "$banned" != 1 ] && { echo "$(date '+%F %T') temiz: ${base}" >> "$STATE"; continue; }
    fi

    ok=1
    $SSHCMD "object-group fqdn domain-list0 include ${base}" >/dev/null 2>&1 || ok=0
    for ip in $(dig +short @$AGH_DNS "$base" 2>/dev/null | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/'); do
        [ "$ip" = "$AGH_DNS" ] && continue
        $SSHCMD "ip route ${ip} $KEEN_IFACE" >/dev/null 2>&1 && echo "$(date '+%F %T') ip:${ip} (${base})" >> "$STATE"
    done
    if [ "$ok" = 1 ]; then
        $SSHCMD "system configuration save" >/dev/null 2>&1
        echo "$(date '+%F %T') ${base} [poison]" >> "$STATE"
    fi
done
