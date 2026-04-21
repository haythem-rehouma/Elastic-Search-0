<a id="top"></a>

# Pratique 5 — Solutions : Installation ES + Kibana (chap. 10)

> Cible : [chapitre 10](../../10-installation-elasticsearch-kibana.md) · Projet runnable : [`pratique-05-ch10-installation-es-kibana/`](./pratique-05-ch10-installation-es-kibana/)

## Objectif

Avoir un **Elasticsearch 8.13 + Kibana 8.13** mono-nœud, sécurité désactivée pour faciliter l'apprentissage, prêt à recevoir des données.

## Solution clé en main

```bash
cd pratique-05-ch10-installation-es-kibana
docker compose up -d
sleep 45
bash scripts/verify.sh    # ou .\scripts\verify.ps1
```

→ ES sur http://localhost:9200, Kibana sur http://localhost:5601.

## Décomposition de la stack

| Variable / volume               | Valeur                            | Pourquoi                                   |
| ------------------------------- | --------------------------------- | ------------------------------------------ |
| `discovery.type`                | `single-node`                     | Évite la recherche d'autres nœuds          |
| `xpack.security.enabled`        | `false`                           | Pas d'auth ni TLS — apprentissage uniquement |
| `ES_JAVA_OPTS`                  | `-Xms512m -Xmx512m`               | Heap limité, suffisant pour P5             |
| `cluster.name`                  | `p05-cluster`                     | Identifie le cluster dans les logs         |
| `node.name`                     | `p05-node-1`                      | Identifie le nœud                          |
| `memlock` ulimit                | unlimited                         | Évite swap → perf ES                       |
| Volume `p05_esdata`             | `/usr/share/elasticsearch/data`   | Persistance                                |
| Healthcheck ES                  | `curl /_cluster/health` `green/yellow` | Kibana attend ES `healthy`            |
| `ELASTICSEARCH_HOSTS` (Kibana)  | `http://elasticsearch:9200`       | Réseau Docker interne, pas `localhost`     |

## Vérifications attendues

| # | Test                                       | Résultat attendu                                  |
| - | ------------------------------------------ | ------------------------------------------------- |
| 1 | `docker ps`                                | `p05_es` et `p05_kibana` au statut `healthy`      |
| 2 | `curl http://localhost:9200`               | JSON avec `"version": { "number": "8.13.x" }`     |
| 3 | `_cluster/health`                          | `"status": "green"` ou `"yellow"`                 |
| 4 | `_cat/indices?v`                           | Indexes système `.kibana_*` listés                |
| 5 | `http://localhost:5601/api/status`         | HTTP 200, contenu `available`                     |
| 6 | `POST /test_p05/_doc` puis `_search`       | Document créé, retrouvé                           |

## Pourquoi sécurité désactivée ?

| Point                                  | Production           | Ce cours              |
| -------------------------------------- | -------------------- | --------------------- |
| Authentification (`elastic` user)      | Obligatoire          | Désactivée            |
| TLS (HTTPS sur 9200)                   | Obligatoire          | Désactivé (HTTP)      |
| API keys                               | Recommandé           | N/A                   |
| Audit log                              | Recommandé           | N/A                   |

> **Désactiver la sécurité enlève le gros frottement pédagogique** (token Kibana, certificats à recopier au boot). On le réactive au [chapitre 17](../../17-labo2-rapport-dsl-news.md) en annexe.

## Pièges classiques

| Erreur                                          | Cause / solution                                                 |
| ----------------------------------------------- | ---------------------------------------------------------------- |
| `max virtual memory areas vm.max_map_count [65530] is too low` | Linux : `sudo sysctl -w vm.max_map_count=262144`        |
| Kibana boucle « Kibana server is not ready »    | ES pas encore healthy. Attendre 60 s. Vérifier `docker logs p05_es`. |
| Conteneur ES s'arrête (exit 137)                | OOM Docker. Augmenter Memory à 4-6 Go dans Docker Desktop.       |
| Kibana ne se connecte pas à ES                  | `ELASTICSEARCH_HOSTS=http://elasticsearch:9200` (pas `localhost` !) |
| Conflit de port 9200 ou 5601                   | Un autre conteneur tourne. `docker ps -a` puis stop ou changer mapping. |

## Test bonus : Dev Tools

Ouvrir Kibana → menu hamburger → **Management → Dev Tools**, puis exécuter :

```
GET _cluster/health

GET _cat/indices?v

PUT essai
{
  "settings": { "number_of_shards": 1, "number_of_replicas": 0 }
}

POST essai/_doc
{ "msg": "Hello ES depuis Kibana" }

GET essai/_search
```

Vous voyez la console divisée en deux : à gauche les requêtes, à droite les réponses.

## Pour aller plus loin

- Pratique suivante (livrable Labo 1) : [`labo-1-solutions-elk.md`](./labo-1-solutions-elk.md)
- Annexe Docker Desktop par OS : [chap. 06 §A](../../06-installation-neo4j.md#annexe-a--installation-de-docker-desktop-windows--macos--linux)

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
