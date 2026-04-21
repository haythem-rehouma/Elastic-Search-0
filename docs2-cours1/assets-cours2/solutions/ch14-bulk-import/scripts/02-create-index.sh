#!/usr/bin/env bash
set -euo pipefail
ES=${ES:-http://localhost:9200}
cd "$(dirname "$0")/.."

echo ">> Suppression de l'index news (si présent)..."
curl -s -X DELETE "$ES/news" >/dev/null || true

echo ">> Création avec mapping optimisé pour l'import (replicas:0, refresh:-1)..."
curl -s -X PUT "$ES/news" \
  -H 'Content-Type: application/json' \
  --data-binary @mappings/news.mapping.json | jq .

echo ">> Mapping créé :"
curl -s "$ES/news/_mapping" | jq '.news.mappings.properties | keys'
