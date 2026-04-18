# backup-auto

Script de sauvegarde automatique avec rotation des archives.

## Usage

```bash
chmod +x backup.sh
./backup.sh <source> <destination> [nb_jours_retention]
```

### Exemples

```bash
# sauvegarde basique, retention 7 jours par defaut
./backup.sh /home/user /mnt/backup

# avec retention personnalisee (30 jours)
./backup.sh /var/www /mnt/backup 30

# sauvegarde d'un projet
./backup.sh /opt/app /backup/projets 14
```

## Fonctionnement

- Cree une archive `tar.gz` horodatee : `backup_<hostname>_YYYYMMDD_HHMMSS.tar.gz`
- Supprime automatiquement les archives plus vieilles que N jours
- Verifie l'espace disque disponible avant de commencer
- Log dans `/var/log/backup.log` (ou `./backup.log` si pas les droits)

## Cron

Ajouter dans `crontab -e` pour une sauvegarde quotidienne a 2h du matin :

```cron
0 2 * * * /opt/scripts/backup.sh /home/user /mnt/backup 7
```

Sauvegarde hebdomadaire le dimanche a 3h :

```cron
0 3 * * 0 /opt/scripts/backup.sh /var/www /backup/web 30
```

## Log

```
[2025-03-15 02:00:01] INFO: debut sauvegarde de /home/user vers /mnt/backup
[2025-03-15 02:00:04] OK: archive creee -> backup_srv01_20250315_020001.tar.gz (245M)
[2025-03-15 02:00:04] SUPPR: /mnt/backup/backup_srv01_20250308_020001.tar.gz
[2025-03-15 02:00:04] INFO: 1 archive(s) supprimee(s)
[2025-03-15 02:00:04] INFO: fin sauvegarde. 7 archive(s) presente(s)
```
