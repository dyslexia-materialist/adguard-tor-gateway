#!/usr/bin/env bash
set -u
source "$(dirname "$0")/../config/gateway.env"
PASSFILE="$KEEN_PASSFILE"

# SSH hedef seç (tünel içi → LAN):
SSH_HOST=""
for h in 10.66.66.5 "$KEEN_HOST"; do
    if timeout 8 sshpass -f "$PASSFILE" ssh -o StrictHostKeyChecking=accept-new \
        "admin@$h" "show version" >/dev/null 2>&1; then SSH_HOST="$h"; break; fi
done
[ -z "$SSH_HOST" ] && { echo "✗ SSH kanalı yok — tünel durumunu kontrol et"; exit 1; }
echo "→ SSH kanalı: $SSH_HOST"
SSHCMD="sshpass -f $PASSFILE ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 admin@$SSH_HOST"

echo "--- Domain listesi re-sync ---"
for d in $(grep -vE '^\s*(#|$)' "$BANNED_LIST"); do
    $SSHCMD "object-group fqdn domain-list0 include $d" >/dev/null 2>&1 && echo "✓ liste: $d"
done

echo "--- IP rotaları ---"
for d in $(grep -vE '^\s*(#|$)' "$BANNED_LIST"); do
    for ip in $(dig +short @$AGH_DNS "$d" 2>/dev/null | awk '/^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/'); do
        [ "$ip" = "$AGH_DNS" ] || [ "$ip" = "0.0.0.0" ] || continue
        $SSHCMD "ip route ${ip} $KEEN_IFACE" >/dev/null 2>&1 && echo "✓ rota: $ip ($d)"
    done
done

$SSHCMD "system configuration save" >/dev/null 2>&1
echo "Restore tamam."
