# scan-reseau

Ping sweep rapide sur une plage reseau locale. Affiche les hotes qui repondent avec leur hostname (resolution DNS inverse).

## Usage

```bash
chmod +x scan.sh
./scan.sh <plage> [-q]
```

### Exemples

```bash
# scan complet avec affichage detaille
./scan.sh 192.168.1

# scan du reseau 10.0.0.x
./scan.sh 10.0.0

# mode silencieux (quiet) : affiche uniquement IP + hostname
./scan.sh 192.168.1 -q

# rediriger la sortie quiet vers un fichier
./scan.sh 192.168.1 -q > hotes_actifs.txt
```

## Sortie

```
=== SCAN RESEAU : 192.168.1.0/24 ===
    2025-03-15 14:32:01
==================================
  [+] 192.168.1.1     router.lan
  [+] 192.168.1.10    nas.local
  [+] 192.168.1.42    pc-bureau.home
  [+] 192.168.1.100   imprimante.lan
  [+] 192.168.1.254   switch-core.lan

==================================
  Scan termine.
```

## Notes

- Scan parallele (20 threads max) pour aller vite
- Necessite `ping`, `host` ou `nslookup` (dispo sur la plupart des distros)
- Sur certains reseaux, les firewalls bloquent les pings -> faux negatifs possibles
- Necessite parfois `sudo` pour que le ping soit plus fiable (ICMP raw socket)
