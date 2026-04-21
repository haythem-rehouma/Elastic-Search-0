<a id="top"></a>

# 12 — Commandes de base d'Elasticsearch (curl)

> **Type** : Pratique · **Pré-requis** : [11 — Labo 1](./11-labo1-mise-en-place-elk.md)

## Table des matières

- [1. Pourquoi `curl` ?](#1-pourquoi-curl-)
- [2. Inspecter le cluster](#2-inspecter-le-cluster)
- [3. Travailler avec les indices](#3-travailler-avec-les-indices)
- [4. Documents : CRUD](#4-documents--crud)
- [5. Recherche simple](#5-recherche-simple)
- [6. Cheatsheet](#6-cheatsheet)

---

## 1. Pourquoi `curl` ?

Avant les UI graphiques, on apprend l'**API REST** d'Elasticsearch en ligne de commande :

- portable (marche partout) ;
- scriptable (CI/CD) ;
- sans dépendance ;
- on **comprend** ce qui se passe.

> Plus tard on remplacera `curl` par **Kibana → Dev Tools** ou par les clients officiels (Python, Node).

### Conventions de ce chapitre

| Variable        | Valeur d'exemple              |
| --------------- | ----------------------------- |
| `ES_URL`        | `http://localhost:9200` (lab) ou `https://localhost:9200` (prod) |
| `ELASTIC_PASSWORD` | défini dans le `.env`      |
| Auth header     | `-u elastic:$ELASTIC_PASSWORD` |
| TLS auto-signé  | `-k`                          |

---

## 2. Inspecter le cluster

### Infos générales

```bash
curl -s http://localhost:9200/ | jq
```

### Santé

```bash
curl -s http://localhost:9200/_cluster/health?pretty
```

| Statut  | Signification                            |
| ------- | ---------------------------------------- |
| green   | Tout est bon, primaires + réplicas OK    |
| yellow  | Primaires OK, réplicas manquants         |
| red     | Au moins un primaire indisponible        |

### Liste des nœuds

```bash
curl -s "http://localhost:9200/_cat/nodes?v"
```

### Liste des indices

```bash
curl -s "http://localhost:9200/_cat/indices?v"
```

### Statistiques globales

```bash
curl -s "http://localhost:9200/_stats" | jq '._all.primaries.docs'
```

---

## 3. Travailler avec les indices

### Créer un index minimal

```bash
curl -X PUT "http://localhost:9200/produits"
```

### Créer un index avec mapping

```bash
curl -X PUT "http://localhost:9200/produits" -H 'Content-Type: application/json' -d '{
  "mappings": {
    "properties": {
      "nom":   { "type": "text" },
      "prix":  { "type": "float" },
      "stock": { "type": "integer" }
    }
  }
}'
```

### Voir le mapping

```bash
curl -s "http://localhost:9200/produits/_mapping?pretty"
```

### Compter les documents

```bash
curl -s "http://localhost:9200/produits/_count?pretty"
```

### Supprimer un index

```bash
curl -X DELETE "http://localhost:9200/produits"
```

---

## 4. Documents : CRUD

### Créer (avec ID)

```bash
curl -X POST "http://localhost:9200/produits/_doc/1" -H 'Content-Type: application/json' -d '{
  "nom": "Casque Bluetooth",
  "prix": 89.90,
  "stock": 12
}'
```

### Créer (auto-ID)

```bash
curl -X POST "http://localhost:9200/produits/_doc" -H 'Content-Type: application/json' -d '{
  "nom": "Souris sans fil",
  "prix": 29.90
}'
```

### Lire un document

```bash
curl -s "http://localhost:9200/produits/_doc/1?pretty"
```

### Mettre à jour partiellement

```bash
curl -X POST "http://localhost:9200/produits/_update/1" -H 'Content-Type: application/json' -d '{
  "doc": { "stock": 8 }
}'
```

### Supprimer un document

```bash
curl -X DELETE "http://localhost:9200/produits/_doc/1"
```

---

## 5. Recherche simple

### Tout

```bash
curl -s "http://localhost:9200/produits/_search?pretty"
```

### Avec un terme via URL

```bash
curl -s "http://localhost:9200/produits/_search?q=nom:casque&pretty"
```

### Avec un body JSON

```bash
curl -s "http://localhost:9200/produits/_search?pretty" -H 'Content-Type: application/json' -d '{
  "query": { "match": { "nom": "casque" } }
}'
```

> On approfondit la recherche au [chapitre 15](./15-requetes-elasticsearch-intermediaire.md) et [16](./16-requetes-avancees-kql-esql-dsl.md). Pour un CRUD plus pédagogique dans Kibana Dev Tools, voir [chapitre 13](./13-crud-pedagogique-kibana.md).

---

## 6. Cheatsheet

| Action                    | Commande                                                       |
| ------------------------- | -------------------------------------------------------------- |
| Cluster info              | `GET /`                                                        |
| Santé                     | `GET /_cluster/health`                                         |
| Liste nœuds               | `GET /_cat/nodes?v`                                            |
| Liste indices             | `GET /_cat/indices?v`                                          |
| Créer index               | `PUT /<index>` (+ mapping JSON)                                |
| Voir mapping              | `GET /<index>/_mapping`                                        |
| Compter                   | `GET /<index>/_count`                                          |
| Supprimer index           | `DELETE /<index>`                                              |
| Créer doc (id)            | `POST /<index>/_doc/<id>`                                      |
| Créer doc (auto-id)       | `POST /<index>/_doc`                                           |
| Lire doc                  | `GET /<index>/_doc/<id>`                                       |
| Update partiel            | `POST /<index>/_update/<id>` body `{"doc": {…}}`              |
| Supprimer doc             | `DELETE /<index>/_doc/<id>`                                    |
| Recherche par URL         | `GET /<index>/_search?q=field:value`                           |
| Recherche par body        | `GET /<index>/_search` body `{"query": {…}}`                   |
| Refresh manuel            | `POST /<index>/_refresh`                                       |

<p align="right"><a href="#top">↑ Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
