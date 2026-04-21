<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# Projet ch14 — Bulk import de 200 853 articles News

Pipeline complet, idempotent : démarre la stack, prépare le dataset, crée l'index, ingère et finalise. **3 implémentations équivalentes** (bash, PowerShell, Python).

## Démarrage en 1 commande

| OS / outil               | Commande                            |
| ------------------------ | ----------------------------------- |
| Linux / macOS / WSL      | `bash scripts/run-all.sh`           |
| Windows PowerShell       | `.\scripts\run-all.ps1`             |
| Python (cross-platform)  | `pip install -r requirements.txt && python scripts/bulk_import.py` |

→ Compte attendu à la fin : **200 853 documents**, sur http://localhost:9200/news.

## Pipeline détaillé (scripts atomiques)

| Étape | Script                              | Rôle                                                |
| ----- | ----------------------------------- | --------------------------------------------------- |
| 0     | `docker compose up -d`              | Démarre ES + Kibana                                 |
| 1     | `scripts/01-prepare.sh`             | Copie le dataset + nettoie CRLF + valide            |
| 2     | `scripts/02-create-index.sh`        | Crée `news` avec mapping `mappings/news.mapping.json` |
| 3     | `scripts/03-convert-and-split.sh`   | Convertit en NDJSON puis split en chunks de 5000    |
| 4     | `scripts/04-bulk-import.sh`         | Boucle d'import avec progression                    |
| 5     | `scripts/05-finalize.sh`            | Réactive replicas/refresh + vérifications           |

## Pré-requis

- Le dataset doit exister à : `../../News_Category_Dataset_v2.json` (déjà présent dans `assets-cours2/`).
- 4 Go RAM libre (ES alloué à 1 Go heap).

## Arborescence

```
pratique-08-ch14-bulk-import/
├── docker-compose.yml          <- ES 1 Go heap + Kibana
├── requirements.txt             <- python deps (helpers.bulk + tqdm)
├── data/
│   ├── raw.jsonl               <- copié depuis assets-cours2/ par 01-prepare
│   ├── news.bulk.ndjson         <- créé par 03-convert-and-split
│   └── chunks/part_*.ndjson     <- ~81 chunks de 5000 lignes
├── mappings/
│   ├── news.mapping.json        <- mapping initial (replicas:0, refresh:-1)
│   └── news.post-import.json    <- réactivation (replicas:1, refresh:1s)
└── scripts/
    ├── 01-prepare.sh
    ├── 02-create-index.sh
    ├── 03-convert-and-split.sh
    ├── 04-bulk-import.sh
    ├── 05-finalize.sh
    ├── run-all.sh               <- pipeline complet bash
    ├── run-all.ps1              <- pipeline complet PowerShell
    └── bulk_import.py           <- pipeline complet Python (helpers.bulk)
```

## Vérifier le résultat

```bash
curl -s http://localhost:9200/news/_count
# {"count":200853, ...}
```

Dans Kibana → Dev Tools :

```
GET news/_search { "track_total_hits": true, "size": 0 }
```

→ `"total": { "value": 200853, "relation": "eq" }`.

## Cleanup

```bash
docker compose down -v                  # supprime tout
rm -rf data/news.bulk.ndjson data/chunks # nettoyer les fichiers générés
```

## Documentation détaillée

[`../pratique-08-solutions-bulk-import.md`](../pratique-08-solutions-bulk-import.md)

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
