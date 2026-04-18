#!/bin/bash
# scan.sh - ping sweep sur une plage reseau locale
# usage: ./scan.sh <plage> [-q]
# ex:    ./scan.sh 192.168.1
#        ./scan.sh 10.0.0 -q

PLAGE="$1"
QUIET=0
HOTES_ACTIFS=0

[ "$2" = "-q" ] || [ "$1" = "-q" ] && QUIET=1
[ "$1" = "-q" ] && PLAGE="$2"

if [ -z "$PLAGE" ]; then
    echo "usage: $0 <plage> [-q]"
    echo "  ex:  $0 192.168.1"
    echo "  ex:  $0 10.0.0 -q"
    exit 1
fi

# validation format plage
if ! echo "$PLAGE" | grep -qE '^([0-9]{1,3}\.){2}[0-9]{1,3}$'; then
    echo "erreur: plage invalide. format attendu: X.X.X (ex: 192.168.1)"
    exit 1
fi

[ $QUIET -eq 0 ] && echo "debug: scan de ${PLAGE}.1 a ${PLAGE}.254..."

[ $QUIET -eq 0 ] && echo ""
[ $QUIET -eq 0 ] && echo "=== SCAN RESEAU : ${PLAGE}.0/24 ==="
[ $QUIET -eq 0 ] && echo "    $(date '+%Y-%m-%d %H:%M:%S')"
[ $QUIET -eq 0 ] && echo "=================================="

# detection OS pour adapter les options ping
PING_OPT="-c 1 -W 1"
if [[ "$OSTYPE" == "darwin"* ]]; then
    PING_OPT="-c 1 -W 1000"
fi

scan_hote() {
    local IP="${PLAGE}.${1}"
    if ping $PING_OPT "$IP" &>/dev/null; then
        # resolution hostname
        HOSTNAME=$(host "$IP" 2>/dev/null | awk '/domain name pointer/{print $5}' | sed 's/\.$//')
        [ -z "$HOSTNAME" ] && HOSTNAME=$(nslookup "$IP" 2>/dev/null | awk '/name =/{print $4}' | sed 's/\.$//')
        [ -z "$HOSTNAME" ] && HOSTNAME="(pas de PTR)"
        if [ $QUIET -eq 0 ]; then
            printf "  [+] %-18s %s\n" "$IP" "$HOSTNAME"
        else
            echo "$IP $HOSTNAME"
        fi
        return 0
    fi
    return 1
}

# scan parallele avec jobs limites
MAX_JOBS=20
ACTIFS=()

for i in $(seq 1 254); do
    scan_hote "$i" &
    # limiter les jobs simultanees
    while [ "$(jobs -r | wc -l)" -ge "$MAX_JOBS" ]; do
        wait -n 2>/dev/null || sleep 0.1
    done
done

wait

# compte les hotes actifs (mode quiet: on compte les lignes)
if [ $QUIET -eq 0 ]; then
    echo ""
    echo "=================================="
    echo "  Scan termine."
fi

exit 0
