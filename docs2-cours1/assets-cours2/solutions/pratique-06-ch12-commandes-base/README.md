<a id="top"></a>

<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. -->
# Projet ch12 — Commandes de base d'Elasticsearch

Stack ES + Kibana standalone + démos `curl`/PowerShell + fichier `.http` clé en main.

## Démarrage

```bash
docker compose up -d
# Patienter ~30s puis :
./scripts/demo.sh                 # Linux/macOS/WSL
# OU
.\scripts\demo.ps1                # Windows
```

→ ES : http://localhost:9200 · Kibana : http://localhost:5601

## Trois manières de jouer les commandes

| Méthode                          | Fichier                 | Quand utiliser                        |
| -------------------------------- | ----------------------- | ------------------------------------- |
| Démo automatisée bash            | `scripts/demo.sh`       | Voir tout fonctionner d'un coup       |
| Démo automatisée PowerShell      | `scripts/demo.ps1`      | Pareil mais sous Windows natif        |
| Manuel via REST Client / IntelliJ| `http/produits.http`    | Coller dans Kibana Dev Tools / VS Code|

## Arborescence

```
pratique-06-ch12-commandes-base/
├── docker-compose.yml          <- ES + Kibana
├── http/
│   └── produits.http            <- 17 requêtes REST Client / IntelliJ HTTP
├── scripts/
│   ├── demo.sh                  <- démo bash en 10 étapes
│   └── demo.ps1                 <- démo PowerShell équivalente
└── README.md
```

## Cleanup

```bash
docker compose down -v
```

## Documentation détaillée

[`../pratique-06-solutions-commandes-base.md`](../pratique-06-solutions-commandes-base.md)

<p align="right"><a href="#top">Retour en haut</a></p>


---

*Copyright © Haythem R - Tous droits reserves.*
<!-- Copyright (c) Haythem Rehouma - InSkillFlow‌​‍​​‍​​​‌​‍​‍​​‍​‌​‍​​‍​​‍‌​‍​​​‍‍​‌​‍​​​‍‍‍‌ - Gneurone. Tous droits reserves. Code tague. Reproduction interdite sans autorisation ecrite. [tag-id: HRIFG] -->
