<a id="top"></a>

# Projet ch11 — Labo 1 ELK (persistance + backup/restore)

Stack ES 8.13.4 + Kibana 8.13.4 standalone, avec scripts de sauvegarde/restauration prêts à l'emploi.

## Démarrage

```bash
./scripts/01-up.sh                  # Linux/macOS/WSL
# OU
.\scripts\01-up.ps1                 # Windows PowerShell
```

→ ES sur http://localhost:9200, Kibana sur http://localhost:5601 (~30 s à se charger).

## Workflow du labo

| # | Action                              | Commande                                                 |
| - | ----------------------------------- | -------------------------------------------------------- |
| 1 | Démarrer la stack                   | `./scripts/01-up.sh`                                     |
| 2 | Tester la persistance               | `./scripts/02-persistence-test.sh`                       |
| 3 | Sauvegarder le volume ES            | `./scripts/03-backup.sh`                                 |
| 4 | Restaurer une sauvegarde            | `./scripts/04-restore.sh backup/ch11_esdata_<date>.tar.gz` |
| 5 | Tout détruire (reset complet)       | `docker compose down -v`                                 |

## Arborescence

```
labo-1-ch11-elk/
├── docker-compose.yml          <- ES + Kibana, volume nommé ch11_esdata
├── backup/                      <- créé automatiquement par 03-backup
│   └── ch11_esdata_*.tar.gz
├── scripts/
│   ├── 01-up.sh / .ps1
│   ├── 02-persistence-test.sh
│   ├── 03-backup.sh / .ps1
│   └── 04-restore.sh
└── README.md
```

## Pourquoi un volume nommé ?

| Critère              | Volume nommé       | Bind-mount       |
| -------------------- | ------------------ | ---------------- |
| Permissions UID 1000 | Géré par Docker    | Souvent à régler |
| Portabilité          | OK                 | Dépend du chemin |
| Sauvegarde           | Facile (tar via container) | Idem      |
| `down -v` efface uniquement le volume Docker | OUI    | NON (touche `/`)|

## Documentation détaillée

[`../labo-1-solutions-elk.md`](../labo-1-solutions-elk.md)

<p align="right"><a href="#top">Retour en haut</a></p>
