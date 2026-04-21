<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# Pratique 1 — Solutions : Installation de Neo4j (chap. 06)

> Cible : [chapitre 06](../../06-installation-neo4j.md) · Projet runnable : [`pratique-01-ch06-installation-neo4j/`](./pratique-01-ch06-installation-neo4j/)

## Objectif

Avoir un Neo4j 5.20 fonctionnel dans Docker en moins de 3 minutes, avec APOC, persistant via volume nommé.

## Solution recommandée (Docker Compose)

```bash
cd pratique-01-ch06-installation-neo4j
docker compose up -d
bash scripts/verify.sh    # ou .\scripts\verify.ps1
```

→ Browser sur http://localhost:7474, identifiants `neo4j` / `Neo4jStrongPass!`.

## Décomposition de la stack

| Élément                        | Valeur                                    | Pourquoi                                |
| ------------------------------ | ----------------------------------------- | --------------------------------------- |
| Image                          | `neo4j:5.20-community`                    | Version stable LTS, gratuite            |
| Port HTTP                      | 7474                                      | Browser web                             |
| Port Bolt                      | 7687                                      | Drivers (Python, Java, etc.)            |
| `NEO4J_AUTH`                   | `neo4j/Neo4jStrongPass!`                  | Évite le 1er reset interactif           |
| `NEO4J_PLUGINS`                | `["apoc"]`                                | Auto-install APOC au boot               |
| `apoc.*` unrestricted          | Oui                                       | Sinon les procédures `apoc.import.*` sont refusées |
| Heap max                       | 2 Go                                      | Suffisant pour les pratiques 2 → 4      |
| Volume `p01_neo4j_data`        | `/data`                                   | Persistance de la base                  |
| Volume `p01_neo4j_logs`        | `/logs`                                   | Garde les logs même après `down`        |
| Volume `p01_neo4j_plugins`     | `/plugins`                                | Cache des plugins téléchargés           |

## Vérifications attendues

| # | Test                          | Résultat attendu                                  |
| - | ----------------------------- | ------------------------------------------------- |
| 1 | `docker ps`                   | Conteneur `p01_neo4j` au statut `healthy`         |
| 2 | `curl http://localhost:7474`  | JSON contenant `"neo4j_version": "5.20.x"`        |
| 3 | Bolt port 7687                | En écoute (`ss -tuln \| grep 7687`)               |
| 4 | `RETURN apoc.version()`       | Retourne une version (ex. `5.20.0`)               |
| 5 | `CREATE (n:Test ...) RETURN n`| Crée et retourne le nœud sans erreur              |

## Pièges classiques

| Erreur                                            | Cause / solution                                                  |
| ------------------------------------------------- | ----------------------------------------------------------------- |
| `Neo.ClientError.Security.Unauthorized`           | Mauvais mot de passe → vérifier `NEO4J_AUTH` du compose            |
| `apoc procedures not found`                       | APOC pas encore chargé, attendre 30 s après le `up`               |
| Conteneur en boucle de redémarrage                | Conflit de port 7474 ou 7687 (autre process sur la machine)       |
| `chown: Read-only file system` au démarrage       | Volume monté en `:ro` → enlever ce flag                           |

## Pour aller plus loin

- [Annexe A du chapitre 06](../../06-installation-neo4j.md#annexe-a--installation-de-docker-desktop-windows--macos--linux) : installation détaillée de Docker Desktop par OS
- Pratique suivante : [`pratique-02-solutions-premiers-pas-cypher.md`](./pratique-02-solutions-premiers-pas-cypher.md)

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
