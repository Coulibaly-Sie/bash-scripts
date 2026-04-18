#!/bin/bash
# backup.sh - sauvegarde automatique avec rotation
# usage: ./backup.sh <source> <destination> [nb_jours_retention]

SOURCE="$1"
DEST="$2"
RETENTION="${3:-7}"

LOGFILE="/var/log/backup.log"
[ ! -w "/var/log" ] && LOGFILE="./backup.log"

DATE=$(date +"%Y%m%d_%H%M%S")
HOSTNAME=$(hostname -s)
ARCHIVE_NAME="backup_${HOSTNAME}_${DATE}.tar.gz"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOGFILE"
}

# verif args
if [ -z "$SOURCE" ] || [ -z "$DEST" ]; then
    echo "usage: $0 <source> <destination> [nb_jours_retention]"
    echo "  ex:  $0 /home/user /mnt/backup 7"
    exit 1
fi

if [ ! -d "$SOURCE" ]; then
    log "ERREUR: dossier source introuvable: $SOURCE"
    exit 1
fi

if [ ! -d "$DEST" ]; then
    log "INFO: creation du dossier destination $DEST"
    mkdir -p "$DEST" || { log "ERREUR: impossible de creer $DEST"; exit 1; }
fi

# espace dispo
ESPACE=$(df -BM "$DEST" | awk 'NR==2 {print $4}' | tr -d 'M')
SOURCE_SIZE=$(du -sm "$SOURCE" 2>/dev/null | awk '{print $1}')
echo "debug: espace dispo=${ESPACE}M, taille source=${SOURCE_SIZE}M"

if [ "$ESPACE" -lt "$SOURCE_SIZE" ]; then
    log "ERREUR: pas assez d'espace disque (dispo: ${ESPACE}M, besoin: ~${SOURCE_SIZE}M)"
    exit 1
fi

log "INFO: debut sauvegarde de $SOURCE vers $DEST/$ARCHIVE_NAME"

# creation archive
tar -czf "$DEST/$ARCHIVE_NAME" -C "$(dirname "$SOURCE")" "$(basename "$SOURCE")" 2>/dev/null
EXIT_CODE=$?

if [ $EXIT_CODE -ne 0 ]; then
    log "ERREUR: tar a echoue avec le code $EXIT_CODE"
    exit 1
fi

TAILLE=$(du -sh "$DEST/$ARCHIVE_NAME" | awk '{print $1}')
log "OK: archive creee -> $ARCHIVE_NAME ($TAILLE)"

# rotation: suppression des vieilles archives
echo "debug: nettoyage des archives de plus de $RETENTION jours..."
NB_SUPPR=0
while IFS= read -r vieux; do
    rm -f "$vieux"
    log "SUPPR: $vieux"
    NB_SUPPR=$((NB_SUPPR + 1))
done < <(find "$DEST" -maxdepth 1 -name "backup_${HOSTNAME}_*.tar.gz" -mtime +"$RETENTION" 2>/dev/null)

[ $NB_SUPPR -gt 0 ] && log "INFO: $NB_SUPPR archive(s) supprimee(s)" || log "INFO: aucune archive a supprimer"

# recap archives restantes
NB_ARCHIVES=$(find "$DEST" -maxdepth 1 -name "backup_${HOSTNAME}_*.tar.gz" | wc -l)
log "INFO: fin sauvegarde. $NB_ARCHIVES archive(s) presente(s) dans $DEST"

exit 0
