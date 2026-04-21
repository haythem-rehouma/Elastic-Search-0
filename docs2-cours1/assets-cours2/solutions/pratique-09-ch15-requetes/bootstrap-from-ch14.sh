#!/usr/bin/env bash
# Si vous voulez que ch15 utilise un index news déjà chargé,
# le plus simple est de lancer ch14 directement et d'utiliser sa stack.
# Ce script propose deux options :
set -euo pipefail
cd "$(dirname "$0")"

cat <<EOF
Deux options pour avoir l'index 'news' (200 853 docs) disponible :

OPTION A — Utiliser la stack ch14 (recommandé)
  cd ../pratique-08-ch14-bulk-import
  bash scripts/run-all.sh
  # → ES sur :9200, Kibana sur :5601 (mêmes ports)
  # → toutes les requêtes ci-dessous fonctionnent immédiatement.

OPTION B — Stack ch15 isolée + ré-import
  docker compose up -d
  # puis :
  cd ../pratique-08-ch14-bulk-import
  ES=http://localhost:9200 bash scripts/01-prepare.sh
  ES=http://localhost:9200 bash scripts/02-create-index.sh
  ES=http://localhost:9200 bash scripts/03-convert-and-split.sh
  ES=http://localhost:9200 bash scripts/04-bulk-import.sh
  ES=http://localhost:9200 bash scripts/05-finalize.sh

Une fois l'index prêt, jouez les requêtes :
  - via Kibana Dev Tools (coller console/all-queries.txt)
  - via CLI :  bash run-query.sh 03-bool-complet.json
EOF
