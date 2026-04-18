#!/bin/bash
# sante.sh - rapport de sante systeme
# affiche CPU, RAM, disque, top processus, connexions reseau, syslog

# codes couleurs ANSI
ROUGE='\033[0;31m'
VERT='\033[0;32m'
JAUNE='\033[1;33m'
BLEU='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

sep() {
    echo -e "${BLEU}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
}

titre() {
    echo -e "\n${BOLD}${CYAN}[ $1 ]${RESET}"
    sep
}

# seuils alertes
SEUIL_CPU=80
SEUIL_RAM=85
SEUIL_DISQUE=90

echo -e "${BOLD}${VERT}"
echo "  ╔══════════════════════════════════════╗"
echo "  ║     RAPPORT SANTE SYSTEME            ║"
echo "  ║  $(date '+%Y-%m-%d %H:%M:%S')  -  $(hostname)  "
echo "  ╚══════════════════════════════════════╝"
echo -e "${RESET}"

# --- CPU ---
titre "CHARGE CPU"
LOAD=$(cat /proc/loadavg 2>/dev/null || uptime | awk -F'load average:' '{print $2}')
LOAD1=$(echo "$LOAD" | awk '{print $1}' | tr -d ',')
NCPU=$(nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 1)
LOAD_PCT=$(echo "$LOAD1 $NCPU" | awk '{printf "%.0f", ($1/$2)*100}')

echo -e "  Load average : ${BOLD}$LOAD1${RESET} (1m)  /  CPUs: $NCPU"
if [ "$LOAD_PCT" -ge "$SEUIL_CPU" ]; then
    echo -e "  Charge CPU   : ${ROUGE}${BOLD}${LOAD_PCT}%  ALERTE${RESET}"
else
    echo -e "  Charge CPU   : ${VERT}${LOAD_PCT}%  OK${RESET}"
fi

# --- RAM ---
titre "MEMOIRE RAM"
if [ -f /proc/meminfo ]; then
    MEM_TOTAL=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    MEM_DISPO=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    MEM_USED=$((MEM_TOTAL - MEM_DISPO))
    MEM_TOTAL_MB=$((MEM_TOTAL / 1024))
    MEM_USED_MB=$((MEM_USED / 1024))
    MEM_PCT=$((MEM_USED * 100 / MEM_TOTAL))
else
    # macOS fallback
    MEM_TOTAL_MB=$(sysctl -n hw.memsize 2>/dev/null | awk '{printf "%.0f", $1/1024/1024}')
    MEM_USED_MB=$(vm_stat 2>/dev/null | awk '/Pages active/{printf "%.0f", $3*4096/1024/1024}')
    MEM_PCT=$(echo "$MEM_USED_MB $MEM_TOTAL_MB" | awk '{printf "%.0f", $1*100/$2}')
fi

echo -e "  Utilisee : ${BOLD}${MEM_USED_MB} Mo${RESET} / ${MEM_TOTAL_MB} Mo"
if [ "$MEM_PCT" -ge "$SEUIL_RAM" ]; then
    echo -e "  Utilisation  : ${ROUGE}${BOLD}${MEM_PCT}%  ALERTE${RESET}"
else
    echo -e "  Utilisation  : ${VERT}${MEM_PCT}%  OK${RESET}"
fi

# --- DISQUE ---
titre "ESPACE DISQUE"
df -h | grep -E '^/dev/' | while read -r ligne; do
    PCT=$(echo "$ligne" | awk '{print $5}' | tr -d '%')
    POINT=$(echo "$ligne" | awk '{print $6}')
    UTIL=$(echo "$ligne" | awk '{print $3}')
    TOTAL=$(echo "$ligne" | awk '{print $2}')
    if [ "$PCT" -ge "$SEUIL_DISQUE" ]; then
        echo -e "  ${ROUGE}${BOLD}[ALERTE] $POINT : ${UTIL}/${TOTAL} (${PCT}%)${RESET}"
    elif [ "$PCT" -ge 70 ]; then
        echo -e "  ${JAUNE}[WARN]   $POINT : ${UTIL}/${TOTAL} (${PCT}%)${RESET}"
    else
        echo -e "  ${VERT}[OK]     $POINT : ${UTIL}/${TOTAL} (${PCT}%)${RESET}"
    fi
done

# --- TOP PROCESSUS ---
titre "TOP 5 PROCESSUS (CPU)"
echo -e "  ${BOLD}PID\tCPU%\tMEM%\tCOMMANDE${RESET}"
ps aux --sort=-%cpu 2>/dev/null | awk 'NR>1 && NR<=6 {printf "  %s\t%s\t%s\t%s\n", $2, $3, $4, $11}' \
    || ps aux 2>/dev/null | sort -rk3 | awk 'NR<=5 {printf "  %s\t%s\t%s\t%s\n", $2, $3, $4, $11}'

# --- CONNEXIONS RESEAU ---
titre "CONNEXIONS RESEAU ACTIVES"
if command -v ss &>/dev/null; then
    echo -e "  ${BOLD}Etat\t\tAdresse locale\t\tAdresse distante${RESET}"
    ss -tn state established 2>/dev/null | awk 'NR>1 {printf "  ESTABLISHED\t%-22s\t%s\n", $4, $5}' | head -10
    NB_CONN=$(ss -tn state established 2>/dev/null | tail -n +2 | wc -l)
    echo -e "\n  Total connexions etablies : ${BOLD}$NB_CONN${RESET}"
elif command -v netstat &>/dev/null; then
    netstat -tn 2>/dev/null | grep ESTABLISHED | awk '{printf "  ESTABLISHED\t%-22s\t%s\n", $4, $5}' | head -10
fi

# --- SYSLOG ---
titre "DERNIERES LIGNES SYSLOG (20)"
SYSLOG=""
for f in /var/log/syslog /var/log/messages /var/log/system.log; do
    [ -r "$f" ] && SYSLOG="$f" && break
done

if [ -n "$SYSLOG" ]; then
    tail -20 "$SYSLOG" | while IFS= read -r line; do
        if echo "$line" | grep -qiE 'error|failed|critical'; then
            echo -e "  ${ROUGE}$line${RESET}"
        elif echo "$line" | grep -qiE 'warn'; then
            echo -e "  ${JAUNE}$line${RESET}"
        else
            echo -e "  $line"
        fi
    done
else
    echo -e "  ${JAUNE}syslog non accessible (essayez avec sudo)${RESET}"
    # fallback: journal systemd
    if command -v journalctl &>/dev/null; then
        echo -e "  ${CYAN}-> journalctl (20 dernieres lignes) :${RESET}"
        journalctl -n 20 --no-pager 2>/dev/null | tail -20
    fi
fi

echo -e "\n${BOLD}${VERT}  Rapport genere le $(date '+%Y-%m-%d a %H:%M:%S')${RESET}\n"
