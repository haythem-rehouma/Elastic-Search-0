<a id="top"></a>

# Pratique 5 — Installation d'Elasticsearch + Kibana (chap. 10)

> Référence : [chapitre 10 — Installation d'Elasticsearch + Kibana](../../../10-installation-elasticsearch-kibana.md)

## Objectif

Installer un **mono-nœud Elasticsearch 8.13** + **Kibana 8.13** dans Docker, avec sécurité désactivée pour faciliter l'apprentissage, et vérifier que tout fonctionne.

## Stack

| Service       | Image                                              | Port  | Rôle                  |
| ------------- | -------------------------------------------------- | :---: | --------------------- |
| Elasticsearch | `docker.elastic.co/elasticsearch/elasticsearch:8.13.4` | 9200 | Moteur + API REST    |
| Kibana        | `docker.elastic.co/kibana/kibana:8.13.4`           | 5601  | UI + Dev Tools        |

Volume nommé : `p05_esdata`.

## Démarrage rapide

```bash
docker compose up -d

# Attendre 30 a 60 secondes que Kibana soit pret
bash scripts/verify.sh
```

PowerShell :

```powershell
docker compose up -d

Start-Sleep -Seconds 45
.\scripts\verify.ps1
```

Puis ouvrir :

- Elasticsearch : http://localhost:9200
- Kibana : http://localhost:5601 → menu **Management → Dev Tools**

## Ce que vérifie le script

1. Les 2 conteneurs `p05_es` et `p05_kibana` sont up
2. ES répond sur `:9200` (version, cluster name)
3. La santé du cluster est `green` ou `yellow`
4. La liste des indexes système (`.kibana_*`) est correcte
5. Kibana répond sur `:5601/api/status`
6. Une écriture + lecture sur l'index `test_p05` réussit

## Configuration importante

Le compose désactive volontairement la sécurité (`xpack.security.enabled=false`) pour ce cours. **Ne jamais faire ça en production.**

Heap ES réglé à 512 Mo (`ES_JAVA_OPTS=-Xms512m -Xmx512m`) — suffisant pour cette installation de découverte. Les pratiques 8 à 10 montent à 1 Go.

## Nettoyage

```bash
docker compose down -v
```

## Prochaine étape

Labo 1 — [`labo-1-ch11-elk/`](../labo-1-ch11-elk/)

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
