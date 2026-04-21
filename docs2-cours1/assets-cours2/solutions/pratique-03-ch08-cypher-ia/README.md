<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# Projet ch08 — Cypher cas pratique IA (Neo4j seul)

Projet **autonome** qui démarre Neo4j 5.20 + APOC, charge les 6 cours, 5 professeurs et toutes les relations en une commande.

## Démarrage en 30 secondes

```bash
cp .env.example .env       # adapter mot de passe si besoin
./run.sh                    # Linux/macOS/WSL
# OU
.\run.ps1                  # Windows PowerShell
```

Puis Neo4j Browser : http://localhost:7474 (login `neo4j` / `spotify123`).

## Arborescence

```
pratique-03-ch08-cypher-ia/
├── docker-compose.yml          <- Neo4j 5.20 + APOC, ports 7474/7687
├── .env.example
├── run.sh / run.ps1            <- Démarre + charge tout via cypher-shell
├── cypher/
│   ├── 01-reset.cypher
│   ├── 02-create-cours.cypher
│   ├── 03-create-profs.cypher
│   ├── 04-prealable-collegues.cypher
│   ├── 05-queries.cypher        <- requêtes d'exploration (manuel, dans Browser)
│   └── 06-updates-deletes.cypher
└── README.md
```

## Vérifications attendues après `run`

| Compteur                | Valeur |
| ----------------------- | -----: |
| Nœuds `cours`           |   6    |
| Nœuds `professeur`      |   5    |
| Relations `ENSEIGNER`   |   5    |
| Relations `PREALABLE`   |   3    |
| Relations `COLLEGUES`   |   3    |

## Aller plus loin

Documentation détaillée : [`../pratique-03-solutions-cypher-cas-ia.md`](../pratique-03-solutions-cypher-cas-ia.md).

## Démolir

```bash
docker compose down -v        # supprime conteneur + volumes (= reset complet)
```

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
