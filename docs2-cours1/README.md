<a id="top"></a>

# Cours — Elasticsearch, Neo4j & la stack ELK

Ce dossier rassemble l'intégralité du cours, réorganisé en **18 chapitres chronologiques** qui vont de la théorie pure jusqu'aux laboratoires pratiques.

> **Étudiants — par où commencer ?**
> 1. **Pratique 1** (CRUD Kibana) : guide pas-à-pas → [`assets-cours2/GUIDE-PRATIQUE-1.md`](./assets-cours2/GUIDE-PRATIQUE-1.md)
> 2. **Pratique 2** (Search/DSL) : guide pas-à-pas → [`assets-cours2/GUIDE-PRATIQUE-2.md`](./assets-cours2/GUIDE-PRATIQUE-2.md)
>
> **Matériel source** (datasets, énoncés .docx du prof) : voir le sous-dossier [`assets-cours2/`](./assets-cours2/).
> **Solutions runnables des exercices** (chapitres 8 à 17) + **setup A à Z** : voir [`assets-cours2/solutions/`](./assets-cours2/solutions/).
> **Projets autonomes par chapitre** (compose + scripts + queries) : voir les dossiers [`assets-cours2/solutions/chXX-*/`](./assets-cours2/solutions/).

## Table des matières

| #   | Titre                                                                                       | Type        |
| --- | ------------------------------------------------------------------------------------------- | ----------- |
| 01  | [Introduction à Elasticsearch & ELK Stack](./01-introduction-elasticsearch-elk-stack.md)    | Théorie     |
| 02  | [SQL vs Documents (Elasticsearch)](./02-theorie-sql-vs-documents.md)                        | Théorie     |
| 03  | [Concepts clés : cluster, shards, mapping, types](./03-concepts-cles-elasticsearch.md)      | Théorie     |
| 04  | [Architecture pipeline ELK + Neo4j](./04-architecture-pipeline-elk-neo4j.md)                | Architecture|
| 05  | [Architecture pipeline ELK + Machine Learning](./05-architecture-pipeline-elk-ml.md)        | Architecture|
| 06  | [Installation de Neo4j (Linux + Docker)](./06-installation-neo4j.md)                        | Pratique    |
| 07  | [Premiers pas en Cypher](./07-premiers-pas-cypher.md)                                       | Pratique    |
| 08  | [Cas pratique Cypher : cours, professeurs, programme IA](./08-cas-pratique-cypher-ia.md)    | Pratique    |
| 09  | [Nettoyage et reset d'une base Neo4j](./09-nettoyage-neo4j.md)                              | Pratique    |
| 10  | [Installation d'Elasticsearch + Kibana](./10-installation-elasticsearch-kibana.md)          | Pratique    |
| 11  | [**Labo 1** — Mise en place complète ELK avec persistance](./11-labo1-mise-en-place-elk.md) | Laboratoire |
| 12  | [Commandes de base d'Elasticsearch (curl)](./12-commandes-base-elasticsearch.md)            | Pratique    |
| 13  | [CRUD pédagogique avec Kibana Dev Tools (`forum`, `liste_cours`)](./13-crud-pedagogique-kibana.md) | Pratique |
| 14  | [Import d'un dataset volumineux (Bulk API)](./14-import-bulk-dataset.md)                    | Pratique    |
| 15  | [Requêtes Elasticsearch — niveau intermédiaire](./15-requetes-elasticsearch-intermediaire.md) | Pratique  |
| 16  | [Requêtes avancées : KQL, ES\|QL, Query DSL](./16-requetes-avancees-kql-esql-dsl.md)        | Pratique    |
| 17  | [**Labo 2** — Rapport DSL sur l'index `news`](./17-labo2-rapport-dsl-news.md)               | Laboratoire |
| 18  | [Annexe — Architectures avancées (Kafka, ML, Computer Vision)](./18-annexe-architectures-avancees.md) | Annexe |

---

## Plan de lecture conseillé

```mermaid
flowchart LR
    A[01-03 Théorie] --> B[04-05 Architecture]
    B --> C[06-09 Neo4j]
    C --> D[10-11 Installation ES + Labo 1]
    D --> E[12-13 CRUD ES + Kibana]
    E --> F[14-16 Bulk + Requêtes]
    F --> G[17 Labo 2]
    G --> H[18 Annexe]
```

| Étape           | Chapitres | Objectif                                                                                                     |
| --------------- | --------- | ------------------------------------------------------------------------------------------------------------ |
| **Théorie**     | 01 → 03   | Comprendre ce qu'est Elasticsearch, en quoi il diffère du SQL, et son vocabulaire (cluster, shards, mapping). |
| **Architecture**| 04 → 05   | Voir comment Elasticsearch s'intègre dans une stack avec Neo4j et un pipeline ML.                            |
| **Neo4j**       | 06 → 09   | Installer Neo4j, écrire ses premières requêtes Cypher, faire un cas pratique, savoir nettoyer.               |
| **Setup ES**    | 10 → 11   | Installer Elasticsearch + Kibana via Docker Compose, puis bâtir un environnement complet (Labo 1).           |
| **CRUD ES**     | 12 → 13   | Apprendre les commandes de base avec `curl`, puis le CRUD pédagogique dans Kibana (PUT vs POST vs `_create`). |
| **Bulk + Requêtes** | 14 → 16 | Charger un gros dataset, puis maîtriser les trois langages de requête (KQL, ES\|QL, DSL).                  |
| **Labo final**  | 17        | Rendre un rapport DSL complet sur le dataset `news`.                                                         |
| **Annexe**      | 18        | Découvrir des architectures avancées (Kafka, ML, Computer Vision).                                           |

---

## Datasets utilisés

| Dataset                                | Emplacement                                               | Utilisé dans          |
| -------------------------------------- | --------------------------------------------------------- | --------------------- |
| Spotify (artists, albums, tracks CSV)  | [`fichiers/`](../fichiers/)                               | Chapitres 06-09 (Neo4j) |
| News Category Dataset v2 (JSON)        | [`assets-cours2/News_Category_Dataset_v2.json`](./assets-cours2/) | Chapitres 14, 15, 16, 17 |
| Datasets compressés (CSV/JSON)         | [`assets-cours2/archive*.zip`](./assets-cours2/)         | Variantes du dataset news |
| Énoncés officiels du prof (.docx)      | [`assets-cours2/Kibana - Pratique *.docx`](./assets-cours2/) | Référence Labo 2       |

---

## Solutions des exercices (clés en main)

Implémentations **complètes et runnables** de tous les exercices et laboratoires, organisées par chapitre. Chaque solution est **auto-suffisante** : on peut partir d'une machine vierge.

| Documentation détaillée                                                                  | Projet runnable (compose + scripts)                                                | Couvre              |
| --------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- | ------------------- |
| [00 — **Setup complet de A à Z**](./assets-cours2/solutions/00-setup-complet-a-z.md)    | (utilise le `docker-compose.yml` racine du projet)                                  | Setup global         |
| [08 — Cypher cas IA](./assets-cours2/solutions/solutions-08-cypher-cas-ia.md)           | [`ch08-cypher-ia/`](./assets-cours2/solutions/ch08-cypher-ia/)                      | Chapitre 08          |
| [11 — Labo 1 ELK](./assets-cours2/solutions/solutions-11-labo1-elk.md)                  | [`ch11-labo1-elk/`](./assets-cours2/solutions/ch11-labo1-elk/)                      | Chapitre 11 (livrable)|
| [12 — Commandes ES](./assets-cours2/solutions/solutions-12-commandes-base.md)           | [`ch12-commandes-base/`](./assets-cours2/solutions/ch12-commandes-base/)            | Chapitre 12          |
| [13 — CRUD Kibana](./assets-cours2/solutions/solutions-13-crud-pedagogique.md)          | [`ch13-crud-kibana/`](./assets-cours2/solutions/ch13-crud-kibana/)                  | Chapitre 13          |
| [14 — Bulk import 200 853 docs](./assets-cours2/solutions/solutions-14-bulk-import.md)  | [`ch14-bulk-import/`](./assets-cours2/solutions/ch14-bulk-import/)                  | Chapitre 14          |
| [15 — Requêtes DSL intermédiaires](./assets-cours2/solutions/solutions-15-requetes-intermediaires.md) | [`ch15-requetes/`](./assets-cours2/solutions/ch15-requetes/)            | Chapitre 15          |
| [16 — KQL vs ES\|QL vs DSL](./assets-cours2/solutions/solutions-16-kql-esql-dsl.md)     | [`ch16-kql-esql-dsl/`](./assets-cours2/solutions/ch16-kql-esql-dsl/)                | Chapitre 16          |
| [17 — Labo 2 News](./assets-cours2/solutions/solutions-17-labo2.md)                     | [`ch17-labo2/`](./assets-cours2/solutions/ch17-labo2/)                              | Chapitre 17 (livrable)|
| [Index complet des solutions](./assets-cours2/solutions/README.md)                      | (index général)                                                                     | Tous                 |

> **Vous démarrez ?** Lisez d'abord le [Setup A à Z](./assets-cours2/solutions/00-setup-complet-a-z.md) puis attaquez les chapitres dans l'ordre.

---

## Conventions de ce cours

| Symbole / Style | Signification                                                                   |
| --------------- | ------------------------------------------------------------------------------- |
| Théorie         | Chapitre conceptuel, pas de manipulation                                        |
| Pratique        | Commandes shell ou Cypher à exécuter                                            |
| Laboratoire     | Travail à rendre, exercices structurés                                          |
| Annexe          | Compléments / approfondissements optionnels                                     |

Tous les blocs `bash` sont prévus pour une **VM Ubuntu** ou un **WSL2 Windows**.
Tous les blocs `cypher` sont compatibles **Neo4j 5.x** (sauf mention contraire).
Les requêtes Elasticsearch ciblent **Elasticsearch 8.x**.

<p align="right"><a href="#top">Retour en haut</a></p>
