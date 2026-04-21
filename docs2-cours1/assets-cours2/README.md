<a id="top"></a>

# assets-cours2 — Matériel source du cours Elasticsearch

Ce dossier contient :

- les **datasets** (JSON et CSV) à charger dans Elasticsearch ;
- les **énoncés officiels** des laboratoires (`.docx`) ;
- les **solutions runnables** des exercices, dans [`solutions/`](./solutions/).

> La **documentation pédagogique** (théorie, marche à suivre, explications) se trouve dans le dossier parent [`docs2-cours1/`](../README.md). Les **implémentations concrètes** des exercices sont ici, dans [`solutions/`](./solutions/).

## Démarrage rapide (depuis zéro)

| Vous voulez…                                 | Allez à                                                            |
| -------------------------------------------- | ------------------------------------------------------------------ |
| **Faire la Pratique 1** (CRUD Kibana — guide étudiant pas-à-pas) | [`GUIDE-PRATIQUE-1.md`](./GUIDE-PRATIQUE-1.md) |
| **Faire la Pratique 2** (Search/DSL — guide étudiant pas-à-pas)  | [`GUIDE-PRATIQUE-2.md`](./GUIDE-PRATIQUE-2.md) |
| **Tout installer de A à Z** (Docker + ELK + Neo4j + Jupyter) | [`solutions/00-setup-complet-a-z.md`](./solutions/00-setup-complet-a-z.md) |
| **Lancer un projet runnable d'un chapitre**  | [`solutions/chXX-*/README.md`](./solutions/) (compose + scripts dédiés) |
| Voir la liste des solutions par chapitre     | [`solutions/README.md`](./solutions/README.md)                     |
| Lire les énoncés originaux du prof           | `Kibana - Pratique 1.docx`, `Kibana - Pratique 2.docx` (ce dossier) |

## Contenu

| Fichier                              | Taille  | Description                                                       | Utilisé dans                                     |
| ------------------------------------ | ------: | ----------------------------------------------------------------- | ------------------------------------------------ |
| `News_Category_Dataset_v2.json`      |  ~84 Mo | Dataset complet (~200 853 articles : `category`, `headline`, `authors`, `link`, `short_description`, `date`) | Chapitres [14](../14-import-bulk-dataset.md), [15](../15-requetes-elasticsearch-intermediaire.md), [16](../16-requetes-avancees-kql-esql-dsl.md), [17](../17-labo2-rapport-dsl-news.md) |
| `archiveJSON.zip`                    |  ~27 Mo | Variante compressée du dataset au format JSON                     | Idem (alternative)                               |
| `archiveCSV.zip`                     |  ~22 Mo | Variante compressée du dataset au format CSV                      | Idem (alternative)                               |
| `Kibana - Pratique 1.docx`           |  24 Ko  | Énoncé officiel du prof — Pratique 1 (CRUD Kibana)                | Référence pour les chapitres 12-13              |
| `Kibana - Pratique 2.docx`           |  20 Ko  | Énoncé officiel du prof — Pratique 2 (Search API + DSL)           | Référence pour les chapitres 15-17              |
| [`solutions/`](./solutions/)         | dossier | **Implémentations runnables** des exercices (chapitres 8 à 17) + setup A-Z | Tous les chapitres avec exercices |

## Comment utiliser ce dossier

### 1. Décompresser les archives (optionnel)

Si vous préférez travailler avec les versions zippées :

```bash
cd docs2-cours1/assets-cours2/
unzip archiveJSON.zip
unzip archiveCSV.zip
```

### 2. Charger le dataset dans Elasticsearch

Suivez la procédure du chapitre [14 — Bulk import](../14-import-bulk-dataset.md). En résumé :

```bash
awk '{print "{\"index\":{\"_index\":\"news\"}}"; print}' News_Category_Dataset_v2.json > news.bulk.ndjson

curl -s -H 'Content-Type: application/x-ndjson' \
     -X POST 'http://localhost:9200/_bulk?pretty' \
     --data-binary @news.bulk.ndjson | jq '.errors'
```

### 3. Référence aux énoncés officiels

Les `.docx` du prof sont la **source d'autorité** pour les exigences des labos :

- **Pratique 1** (`Kibana - Pratique 1.docx`)
  - **Guide étudiant pas-à-pas** : [`GUIDE-PRATIQUE-1.md`](./GUIDE-PRATIQUE-1.md)
  - Cours théorique : [chapitre 13 — CRUD pédagogique](../13-crud-pedagogique-kibana.md)
  - Solution complète : [`solutions/pratique-07-solutions-crud-pedagogique.md`](./solutions/pratique-07-solutions-crud-pedagogique.md)
  - Projet runnable : [`solutions/pratique-07-ch13-crud-kibana/`](./solutions/pratique-07-ch13-crud-kibana/)
- **Pratique 2** (`Kibana - Pratique 2.docx`)
  - **Guide étudiant pas-à-pas** : [`GUIDE-PRATIQUE-2.md`](./GUIDE-PRATIQUE-2.md)
  - Cours théorique : chapitres [14](../14-import-bulk-dataset.md), [15](../15-requetes-elasticsearch-intermediaire.md), [16](../16-requetes-avancees-kql-esql-dsl.md), [17 — Labo 2](../17-labo2-rapport-dsl-news.md)
  - Solutions complètes : [`solutions-14`](./solutions/pratique-08-solutions-bulk-import.md), [`solutions-15`](./solutions/pratique-09-solutions-requetes-intermediaires.md), [`solutions-16`](./solutions/pratique-10-solutions-kql-esql-dsl.md), [`solutions-17`](./solutions/labo-2-solutions-rapport-dsl-news.md)
  - Projets runnables : [`pratique-08-ch14-bulk-import/`](./solutions/pratique-08-ch14-bulk-import/), [`pratique-09-ch15-requetes/`](./solutions/pratique-09-ch15-requetes/), [`pratique-10-ch16-kql-esql-dsl/`](./solutions/pratique-10-ch16-kql-esql-dsl/), [`labo-2-ch17-labo2/`](./solutions/labo-2-ch17-labo2/)

## Pourquoi un sous-dossier séparé ?

| Question                                           | Réponse                                                                              |
| -------------------------------------------------- | ------------------------------------------------------------------------------------ |
| Pourquoi ne pas mettre les `.docx` dans `docs2-cours1/` directement ? | `docs2-cours1/` ne contient que du **Markdown** (versionnable, diff-able, lisible sur GitHub). |
| Pourquoi ne pas mettre les datasets dans `fichiers/` ? | `fichiers/` est **réservé** aux CSV Spotify utilisés par Neo4j (cours sur les graphes). |
| Pourquoi pas un seul gros dossier `data/` ?        | Sépare clairement les datasets du **cours 1** (Spotify, graphes) et du **cours 2** (news, recherche full-text). |

## Arborescence du dépôt

```
elasticsearch-1/
├── docs2-cours1/             <- Cours complet (18 chapitres Markdown)
│   ├── README.md
│   ├── 01..18-*.md
│   └── assets-cours2/        <- CE DOSSIER
│       ├── README.md
│       ├── News_Category_Dataset_v2.json
│       ├── archiveJSON.zip
│       ├── archiveCSV.zip
│       ├── Kibana - Pratique 1.docx
│       ├── Kibana - Pratique 2.docx
│       └── solutions/        <- DOC + PROJETS RUNNABLES par chapitre
│           ├── README.md
│           ├── 00-setup-complet-a-z.md
│           ├── solutions-*.md            (8 fichiers de doc détaillée)
│           ├── pratique-03-ch08-cypher-ia/           <- compose Neo4j + cypher/ + run.sh/.ps1
│           ├── labo-1-ch11-elk/           <- compose ES+KB + scripts backup/restore
│           ├── pratique-06-ch12-commandes-base/      <- compose + http/ + scripts demo
│           ├── pratique-07-ch13-crud-kibana/         <- compose + console/ snippets
│           ├── pratique-08-ch14-bulk-import/         <- compose + mappings/ + run-all.sh/.ps1/.py
│           ├── pratique-09-ch15-requetes/            <- compose + queries/ + console/
│           ├── pratique-10-ch16-kql-esql-dsl/        <- compose + console/ KQL/ESQL/DSL
│           └── labo-2-ch17-labo2/               <- compose + mappings/ + queries/R01..R10/ + scripts/ + docs/rapport-template.md
├── fichiers/                 <- Datasets Spotify (CSV) pour Neo4j
├── cypher/                   <- Scripts Cypher de chargement
├── notebooks/                <- Notebooks Jupyter
├── scripts/                  <- Scripts utilitaires
├── docker-compose.yml
└── README.md
```

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
